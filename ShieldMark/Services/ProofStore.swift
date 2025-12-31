import Foundation

/// Proof creation + verification with local persistence.
actor ProofStore {
    enum ProofError: Error, Equatable {
        case noStoredProofs
        case invalidPayload
    }

    struct VerificationResult: Sendable {
        var isValid: Bool
        var matchedRecord: ProofRecord?
        var reason: String
    }

    private let hasher: ProofHasher
    private let signer: CryptoSigner
    private let incidentLogger: IncidentLogger
    private let storageURL: URL
    private let signingAlgorithm: CryptoSigner.SigningAlgorithm

    private var records: [ProofRecord] = []

    init(
        hasher: ProofHasher,
        signer: CryptoSigner,
        incidentLogger: IncidentLogger,
        signingAlgorithm: CryptoSigner.SigningAlgorithm = .ed25519,
        filename: String = "proofs.json"
    ) throws {
        self.hasher = hasher
        self.signer = signer
        self.incidentLogger = incidentLogger
        let base = try AppPaths.applicationSupportDirectory()
        self.storageURL = base.appendingPathComponent(filename, isDirectory: false)
        self.signingAlgorithm = signingAlgorithm
        self.records = (try? Self.load(from: storageURL)) ?? []
    }

    func list() -> [ProofRecord] {
        records.sorted { $0.payload.createdAt > $1.payload.createdAt }
    }

    func createProof(for data: Data, label: String? = nil, mediaUTType: String? = nil) async throws -> ProofRecord {
        let hash = hasher.sha256(data)
        let message = Self.signingMessageV1(contentHash: hash)
        let signed = try signer.sign(message: message, algorithm: signingAlgorithm)

        let payload = ProofPayload(
            version: 1,
            hashAlgorithm: .sha256,
            contentHash: hash,
            signatureAlgorithm: signed.algorithm,
            signerPublicKey: signed.publicKey,
            signature: signed.signature,
            createdAt: Date()
        )

        let record = ProofRecord(label: label, mediaUTType: mediaUTType, payload: payload)
        records.append(record)
        try Self.save(records, to: storageURL)
        try await incidentLogger.append(IncidentEvent(kind: .proofCreated, severity: .info, message: "Proof created", metadata: [
            "recordId": record.id.uuidString
        ]))
        return record
    }

    func verify(data: Data) async throws -> VerificationResult {
        guard !records.isEmpty else { throw ProofError.noStoredProofs }

        let hash = hasher.sha256(data)
        let candidates = records.filter { $0.payload.contentHash == hash }
        if candidates.isEmpty {
            return VerificationResult(isValid: false, matchedRecord: nil, reason: "No stored proof matches this file hash.")
        }

        // Verify signature against payload.
        for record in candidates {
            let payload = record.payload
            let message = Self.signingMessageV1(contentHash: payload.contentHash)
            let ok = signer.verify(
                signature: payload.signature,
                message: message,
                publicKey: payload.signerPublicKey,
                algorithm: payload.signatureAlgorithm
            )
            if ok {
                try await incidentLogger.append(IncidentEvent(kind: .proofVerified, severity: .info, message: "Proof verified", metadata: [
                    "recordId": record.id.uuidString
                ]))
                return VerificationResult(isValid: true, matchedRecord: record, reason: "Signature valid and hash matches stored proof.")
            }
        }

        return VerificationResult(isValid: false, matchedRecord: candidates.first, reason: "Hash matched but signature did not validate.")
    }

    // MARK: - Signing format

    static func signingMessageV1(contentHash: Data) -> Data {
        var message = Data("ShieldMarkProofV1|sha256|".utf8)
        message.append(contentHash)
        return message
    }

    // MARK: - Persistence

    private static func load(from url: URL) throws -> [ProofRecord] {
        let fm = FileManager.default
        guard fm.fileExists(atPath: url.path) else { return [] }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([ProofRecord].self, from: data)
    }

    private static func save(_ records: [ProofRecord], to url: URL) throws {
        let data = try JSONEncoder().encode(records)
        try data.write(to: url, options: [.atomic])
    }
}

