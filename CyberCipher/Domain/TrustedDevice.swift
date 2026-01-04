import Foundation

/// A locally-enrolled trusted device (MVP: local list only).
struct TrustedDevice: Codable, Identifiable, Hashable, Sendable {
    enum Status: String, Codable, Hashable, Sendable {
        case active
        case revoked
    }

    var id: UUID
    var displayName: String
    var enrolledAt: Date
    var status: Status

    init(
        id: UUID = UUID(),
        displayName: String,
        enrolledAt: Date = Date(),
        status: Status = .active
    ) {
        self.id = id
        self.displayName = displayName
        self.enrolledAt = enrolledAt
        self.status = status
    }
}

