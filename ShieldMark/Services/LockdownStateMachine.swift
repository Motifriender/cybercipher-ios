import Foundation

/// Manages Emergency Lockdown state + trusted-device enrollment (MVP: local list).
///
/// Re-auth is handled elsewhere (UI) but state transitions are enforced here.
actor LockdownStateMachine {
    enum TransitionError: Error, Equatable {
        case alreadyLocked
        case notLocked
        case notAwaitingReauth
        case unlockNotPermitted
        case deviceNotFound
    }

    private let keychain: KeychainStore
    private let incidentLogger: IncidentLogger

    private let stateAccount = "lockdown.state"
    private let devicesAccount = "lockdown.trustedDevices"

    private(set) var state: LockdownState
    private(set) var trustedDevices: [TrustedDevice]

    init(keychain: KeychainStore, incidentLogger: IncidentLogger) {
        self.keychain = keychain
        self.incidentLogger = incidentLogger
        self.state = (try? keychain.getCodable(LockdownState.self, account: stateAccount)) ?? LockdownState()
        self.trustedDevices = (try? keychain.getCodable([TrustedDevice].self, account: devicesAccount)) ?? []
    }

    func engagePanic(reason: String = "User engaged panic button") async throws {
        guard state.mode == .unlocked else { throw TransitionError.alreadyLocked }
        state.mode = .locked
        state.engagedAt = Date()
        try persistState()
        try await incidentLogger.append(IncidentEvent(kind: .lockdownEngaged, severity: .critical, message: reason))
        try await incidentLogger.append(IncidentEvent(kind: .vaultLocked, severity: .critical, message: "Vault locked due to lockdown"))
    }

    func beginUnlockAttempt() async throws {
        guard state.mode == .locked else { throw TransitionError.notLocked }
        state.mode = .awaitingReauth
        try persistState()
        try await incidentLogger.append(IncidentEvent(kind: .lockdownUnlockAttempt, severity: .warning, message: "Unlock attempt started (awaiting re-auth)"))
    }

    func completeUnlock(success: Bool) async throws {
        guard state.mode == .awaitingReauth else { throw TransitionError.notAwaitingReauth }
        if success {
            state.mode = .unlocked
            state.lastUnlockAt = Date()
            try persistState()
            try await incidentLogger.append(IncidentEvent(kind: .lockdownUnlocked, severity: .info, message: "Lockdown cleared"))
            try await incidentLogger.append(IncidentEvent(kind: .vaultUnlocked, severity: .info, message: "Vault unlocked"))
        } else {
            // Return to locked; keep engagedAt.
            state.mode = .locked
            try persistState()
            try await incidentLogger.append(IncidentEvent(kind: .securityWarning, severity: .warning, message: "Re-auth failed; vault remains locked"))
        }
    }

    func enrollThisDevice(displayName: String) async throws -> TrustedDevice {
        let device = TrustedDevice(displayName: displayName, enrolledAt: Date(), status: .active)
        trustedDevices.append(device)
        try persistDevices()
        try await incidentLogger.append(IncidentEvent(kind: .trustedDeviceEnrolled, severity: .info, message: "Trusted device enrolled: \(displayName)"))
        return device
    }

    func revokeDevice(id: UUID) async throws {
        guard let idx = trustedDevices.firstIndex(where: { $0.id == id }) else { throw TransitionError.deviceNotFound }
        let name = trustedDevices[idx].displayName
        trustedDevices[idx].status = .revoked
        try persistDevices()
        try await incidentLogger.append(IncidentEvent(kind: .trustedDeviceRemoved, severity: .warning, message: "Trusted device revoked: \(name)"))
    }

    private func persistState() throws {
        try keychain.setCodable(state, account: stateAccount)
    }

    private func persistDevices() throws {
        try keychain.setCodable(trustedDevices, account: devicesAccount)
    }
}

