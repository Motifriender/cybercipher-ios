import Foundation

/// A portable, verifiable proof payload for a given file hash.
///
/// This is what you can export/share to verify authenticity elsewhere.
struct ProofPayload: Codable, Hashable, Sendable {
    enum Algorithm: String, Codable, Hashable, Sendable {
        case sha256
    }

    enum SignatureAlgorithm: String, Codable, Hashable, Sendable {
        case ed25519
        case p256
    }

    /// Schema version for forward compatibility.
    var version: Int

    /// Hash algorithm used for `contentHash`.
    var hashAlgorithm: Algorithm

    /// Hash bytes of the underlying content (e.g. photo bytes).
    var contentHash: Data

    /// Signature algorithm used for `signature`.
    var signatureAlgorithm: SignatureAlgorithm

    /// Public key bytes (raw) for the signer.
    var signerPublicKey: Data

    /// Signature bytes over the canonical payload signing message.
    var signature: Data

    /// When the proof was created.
    var createdAt: Date

    init(
        version: Int = 1,
        hashAlgorithm: Algorithm = .sha256,
        contentHash: Data,
        signatureAlgorithm: SignatureAlgorithm,
        signerPublicKey: Data,
        signature: Data,
        createdAt: Date = Date()
    ) {
        self.version = version
        self.hashAlgorithm = hashAlgorithm
        self.contentHash = contentHash
        self.signatureAlgorithm = signatureAlgorithm
        self.signerPublicKey = signerPublicKey
        self.signature = signature
        self.createdAt = createdAt
    }
}

