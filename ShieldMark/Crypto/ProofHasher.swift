import CryptoKit
import Foundation

struct ProofHasher: Sendable {
    func sha256(_ data: Data) -> Data {
        let digest = SHA256.hash(data: data)
        return Data(digest)
    }
}

