import LocalAuthentication
import SwiftUI

struct LockdownView: View {
    @EnvironmentObject private var container: AppContainer

    @State private var lockdownState: LockdownState = LockdownState()
    @State private var trustedDevices: [TrustedDevice] = []
    @State private var statusText: String?

    @State private var showEnroll = false
    @State private var enrollName = ""

    var body: some View {
        List {
            Section("Emergency Lockdown") {
                HStack {
                    Text("State")
                    Spacer()
                    Text(lockdownState.mode.rawValue)
                        .foregroundStyle(lockdownState.mode == .unlocked ? .green : .red)
                }

                if let engagedAt = lockdownState.engagedAt {
                    Text("Engaged: \(engagedAt.formatted())")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Button(role: .destructive) {
                    Task {
                        do {
                            try await container.lockdown.engagePanic()
                            statusText = "Lockdown engaged."
                            await refresh()
                        } catch {
                            statusText = "Failed to engage: \(error)"
                        }
                    }
                } label: {
                    Label("Panic Button (Lock Vault)", systemImage: "exclamationmark.triangle")
                }
                .disabled(lockdownState.mode != .unlocked)

                Button {
                    Task {
                        do {
                            try await container.lockdown.beginUnlockAttempt()
                            let ok = await authenticateWithDeviceOwner()
                            try await container.lockdown.completeUnlock(success: ok)
                            statusText = ok ? "Unlocked." : "Re-auth failed."
                            await refresh()
                        } catch {
                            statusText = "Unlock failed: \(error)"
                        }
                    }
                } label: {
                    Label("Unlock (requires re-auth)", systemImage: "faceid")
                }
                .disabled(lockdownState.mode == .unlocked)

                Text("Re-auth MVP uses device owner auth (Face ID/Touch ID/Passcode). Passkey-based re-auth is a TODO that requires a relying party + associated domain.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if let statusText {
                    Text(statusText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Trusted Devices (local MVP)") {
                Button {
                    enrollName = ""
                    showEnroll = true
                } label: {
                    Label("Enroll this device", systemImage: "plus")
                }

                if trustedDevices.isEmpty {
                    Text("None enrolled yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(trustedDevices) { device in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(device.displayName)
                            Text("\(device.status.rawValue) • \(device.enrolledAt.formatted())")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Lockdown")
        .task { await refresh() }
        .refreshable { await refresh() }
        .sheet(isPresented: $showEnroll) {
            NavigationStack {
                Form {
                    TextField("Device name", text: $enrollName)
                }
                .navigationTitle("Enroll Device")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showEnroll = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Enroll") {
                            let name = enrollName.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !name.isEmpty else { return }
                            Task {
                                do {
                                    _ = try await container.lockdown.enrollThisDevice(displayName: name)
                                    showEnroll = false
                                    await refresh()
                                } catch {
                                    statusText = "Enroll failed: \(error)"
                                    showEnroll = false
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func refresh() async {
        lockdownState = await container.lockdown.state
        trustedDevices = await container.lockdown.trustedDevices
    }

    private func authenticateWithDeviceOwner() async -> Bool {
        let context = LAContext()
        let reason = "Unlock CyberCipher vault"
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            return await withCheckedContinuation { continuation in
                context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, _ in
                    continuation.resume(returning: success)
                }
            }
        } else {
            return false
        }
    }
}

#Preview {
    NavigationStack { LockdownView() }
        .environmentObject(AppContainer())
}

