import Foundation

/// Locally stored record of a proof created for an item.
struct ProofRecord: Codable, Identifiable, Hashable, Sendable {
    var id: UUID

    /// Optional user-facing label (filename, note, etc.).
    var label: String?

    /// Optional original media type for UX.
    var mediaUTType: String?

    /// The verifiable payload.
    var payload: ProofPayload

    init(
        id: UUID = UUID(),
        label: String? = nil,
        mediaUTType: String? = nil,
        payload: ProofPayload
    ) {
        self.id = id
        self.label = label
        self.mediaUTType = mediaUTType
        self.payload = payload
    }
}

