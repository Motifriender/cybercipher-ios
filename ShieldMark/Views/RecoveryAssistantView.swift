import SwiftUI

/// Advisory-only recovery guidance (no automatic actions).
struct RecoveryAssistantView: View {
    @EnvironmentObject private var container: AppContainer

    @State private var guidanceText: String = "Tap Generate to get recovery guidance based on your incident timeline."
    @State private var isGenerating = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Recovery Assistant")
                    .font(.title2.bold())

                Text("Advisory only: this screen cannot approve devices or change security settings.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Button {
                    Task { await generate() }
                } label: {
                    Label(isGenerating ? "Generating…" : "Generate Guidance", systemImage: "sparkles")
                }
                .disabled(isGenerating)

                Text(guidanceText)
                    .font(.body)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
            }
            .padding()
        }
        .navigationTitle("Recovery")
    }

    private func generate() async {
        isGenerating = true
        defer { isGenerating = false }

        let events = await container.incidentLogger.listNewestFirst(limit: 50)
        let state = await container.lockdown.state

        let summary = [
            "## Summary",
            "- Lockdown state: \(state.mode.rawValue)",
            "- Recent events analyzed: \(events.count)",
            events.first.map { "- Most recent: \($0.kind.rawValue) at \($0.timestamp.formatted())" } ?? "- Most recent: none",
            "",
        ].joined(separator: "\n")

        var checklist: [String] = []
        checklist.append("## Recovery checklist (suggested)")
        checklist.append("- Confirm your device is in your physical possession and on a trusted network.")

        if state.mode != .unlocked {
            checklist.append("- Keep the vault locked until you finish verification steps.")
            checklist.append("- Attempt unlock only after verifying device integrity (OS updates, no suspicious profiles).")
        } else {
            checklist.append("- Review the incident timeline for any unexpected activity.")
        }

        if events.contains(where: { $0.kind == .trustedDeviceEnrolled || $0.kind == .trustedDeviceRemoved }) {
            checklist.append("- Review trusted devices and revoke anything you don’t recognize.")
        } else {
            checklist.append("- Consider enrolling this device as trusted after you’re confident it’s secure.")
        }

        checklist.append("- Rotate any impacted secrets outside the app (email, social, cloud) using official account settings.")
        checklist.append("- Enable multi-factor authentication where available (prefer hardware keys or passkeys).")
        checklist.append("- After recovery, create fresh content proofs for new sensitive media.")

        let output = summary + checklist.joined(separator: "\n")
        guidanceText = output

        try? await container.incidentLogger.append(
            IncidentEvent(kind: .recoveryAssistantRequested, severity: .info, message: "Recovery assistant guidance generated")
        )
    }
}

#Preview {
    NavigationStack { RecoveryAssistantView() }
        .environmentObject(AppContainer())
}

