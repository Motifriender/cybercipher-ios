import Foundation

/// An item stored in the local vault.
///
/// Data-at-rest encryption is handled by `VaultStore`; this model is a logical record.
struct VaultItem: Codable, Identifiable, Hashable, Sendable {
    enum Kind: String, Codable, Hashable, Sendable {
        case proof
        case note
        case blob
    }

    var id: UUID
    var kind: Kind
    var title: String
    var createdAt: Date
    var updatedAt: Date

    /// Opaque payload reference (e.g. encrypted blob key or pointer).
    var reference: String?

    init(
        id: UUID = UUID(),
        kind: Kind,
        title: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        reference: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.reference = reference
    }
}

