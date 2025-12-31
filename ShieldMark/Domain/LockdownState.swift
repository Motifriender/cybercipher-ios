import Foundation

/// High-level state of the vault lockdown.
struct LockdownState: Codable, Hashable, Sendable {
    enum Mode: String, Codable, Hashable, Sendable {
        /// Normal operation.
        case unlocked
        /// Panic engaged: vault is locked and sensitive operations are blocked.
        case locked
        /// Locked and awaiting re-auth.
        case awaitingReauth
    }

    var mode: Mode
    var engagedAt: Date?
    var lastUnlockAt: Date?

    init(mode: Mode = .unlocked, engagedAt: Date? = nil, lastUnlockAt: Date? = nil) {
        self.mode = mode
        self.engagedAt = engagedAt
        self.lastUnlockAt = lastUnlockAt
    }
}

