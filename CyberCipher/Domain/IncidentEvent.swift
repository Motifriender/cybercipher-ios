import Foundation

/// Append-only security incident event.
struct IncidentEvent: Codable, Identifiable, Hashable, Sendable {
    enum Kind: String, Codable, Hashable, Sendable {
        case appLaunch
        case proofCreated
        case proofVerified
        case lockdownEngaged
        case lockdownUnlockAttempt
        case lockdownUnlocked
        case trustedDeviceEnrolled
        case trustedDeviceRemoved
        case vaultLocked
        case vaultUnlocked
        case recoveryAssistantRequested
        case securityWarning
    }

    enum Severity: String, Codable, Hashable, Sendable {
        case info
        case warning
        case critical
    }

    var id: UUID
    var kind: Kind
    var severity: Severity
    var timestamp: Date
    var message: String
    var metadata: [String: String]

    init(
        id: UUID = UUID(),
        kind: Kind,
        severity: Severity = .info,
        timestamp: Date = Date(),
        message: String,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.kind = kind
        self.severity = severity
        self.timestamp = timestamp
        self.message = message
        self.metadata = metadata
    }
}

