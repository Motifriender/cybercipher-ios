import CryptoKit
import Foundation

/// Generates/loads a signing keypair (stored in Keychain) and signs messages.
struct CryptoSigner: Sendable {
    enum SigningAlgorithm: Sendable {
        case ed25519
        case p256
    }

    private let keychain: KeychainStore
    private let privateKeyAccount: String

    init(keychain: KeychainStore, privateKeyAccount: String = "signing.privateKey") {
        self.keychain = keychain
        self.privateKeyAccount = privateKeyAccount
    }

    func getOrCreateKeyPair(algorithm: SigningAlgorithm) throws -> (publicKey: Data, algorithm: ProofPayload.SignatureAlgorithm) {
        switch algorithm {
        case .ed25519:
            let key = try getOrCreateEd25519PrivateKey()
            return (publicKey: key.publicKey.rawRepresentation, algorithm: .ed25519)
        case .p256:
            let key = try getOrCreateP256PrivateKey()
            return (publicKey: key.publicKey.rawRepresentation, algorithm: .p256)
        }
    }

    func sign(message: Data, algorithm: SigningAlgorithm) throws -> (signature: Data, publicKey: Data, algorithm: ProofPayload.SignatureAlgorithm) {
        switch algorithm {
        case .ed25519:
            let key = try getOrCreateEd25519PrivateKey()
            let sig = try key.signature(for: message)
            return (signature: sig, publicKey: key.publicKey.rawRepresentation, algorithm: .ed25519)
        case .p256:
            let key = try getOrCreateP256PrivateKey()
            let sig = try key.signature(for: message)
            return (signature: sig.derRepresentation, publicKey: key.publicKey.rawRepresentation, algorithm: .p256)
        }
    }

    func verify(signature: Data, message: Data, publicKey: Data, algorithm: ProofPayload.SignatureAlgorithm) -> Bool {
        switch algorithm {
        case .ed25519:
            guard let pub = try? Curve25519.Signing.PublicKey(rawRepresentation: publicKey) else { return false }
            return pub.isValidSignature(signature, for: message)
        case .p256:
            guard
                let pub = try? P256.Signing.PublicKey(rawRepresentation: publicKey),
                let sig = try? P256.Signing.ECDSASignature(derRepresentation: signature)
            else { return false }
            return pub.isValidSignature(sig, for: message)
        }
    }

    // MARK: - Key persistence

    private func getOrCreateEd25519PrivateKey() throws -> Curve25519.Signing.PrivateKey {
        let account = "\(privateKeyAccount).ed25519"
        if let data = try keychain.getIfPresent(account: account) {
            return try Curve25519.Signing.PrivateKey(rawRepresentation: data)
        }
        let key = Curve25519.Signing.PrivateKey()
        try keychain.set(key.rawRepresentation, account: account)
        return key
    }

    private func getOrCreateP256PrivateKey() throws -> P256.Signing.PrivateKey {
        let account = "\(privateKeyAccount).p256"
        if let data = try keychain.getIfPresent(account: account) {
            return try P256.Signing.PrivateKey(rawRepresentation: data)
        }
        let key = P256.Signing.PrivateKey()
        try keychain.set(key.rawRepresentation, account: account)
        return key
    }
}

