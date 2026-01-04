import XCTest

@testable import CyberCipher

final class KeychainStoreTests: XCTestCase {
    func testKeychainRoundTripData() throws {
        let keychain = KeychainStore(service: "com.example.CyberCipher.tests.keychain.\(UUID().uuidString)")
        let account = "roundtrip.data"
        let payload = Data("hello".utf8)

        try? keychain.delete(account: account)
        try keychain.set(payload, account: account)
        let loaded = try keychain.get(account: account)
        XCTAssertEqual(loaded, payload)
    }

    func testKeychainRoundTripCodable() throws {
        struct Sample: Codable, Equatable {
            var a: Int
            var b: String
        }

        let keychain = KeychainStore(service: "com.example.CyberCipher.tests.keychain.\(UUID().uuidString)")
        let account = "roundtrip.codable"
        let value = Sample(a: 7, b: "x")

        try? keychain.delete(account: account)
        try keychain.setCodable(value, account: account)
        let loaded = try keychain.getCodable(Sample.self, account: account)
        XCTAssertEqual(loaded, value)
    }
}

final class LockdownStateMachineTests: XCTestCase {
    func testLockdownTransitions() async throws {
        let keychain = KeychainStore(service: "com.example.CyberCipher.tests.lockdown.\(UUID().uuidString)")
        // Ensure clean slate for known accounts.
        try? keychain.delete(account: "lockdown.state")
        try? keychain.delete(account: "lockdown.trustedDevices")

        let logger = try IncidentLogger(filename: "incidents_test_\(UUID().uuidString).json")
        let sm = LockdownStateMachine(keychain: keychain, incidentLogger: logger)

        XCTAssertEqual(await sm.state.mode, .unlocked)

        try await sm.engagePanic()
        XCTAssertEqual(await sm.state.mode, .locked)

        try await sm.beginUnlockAttempt()
        XCTAssertEqual(await sm.state.mode, .awaitingReauth)

        try await sm.completeUnlock(success: false)
        XCTAssertEqual(await sm.state.mode, .locked)

        try await sm.beginUnlockAttempt()
        XCTAssertEqual(await sm.state.mode, .awaitingReauth)

        try await sm.completeUnlock(success: true)
        let final = await sm.state
        XCTAssertEqual(final.mode, .unlocked)
        XCTAssertNotNil(final.lastUnlockAt)
    }
}

final class ProofStoreTests: XCTestCase {
    func testProofCreateAndVerify() async throws {
        let keychain = KeychainStore(service: "com.example.CyberCipher.tests.proofs.\(UUID().uuidString)")
        // Clean signer key so test is deterministic-ish.
        try? keychain.delete(account: "signing.privateKey.ed25519")

        let logger = try IncidentLogger(filename: "incidents_test_\(UUID().uuidString).json")
        let store = try ProofStore(
            hasher: ProofHasher(),
            signer: CryptoSigner(keychain: keychain),
            incidentLogger: logger,
            signingAlgorithm: .ed25519,
            filename: "proofs_test_\(UUID().uuidString).json"
        )

        let data = Data("hello world".utf8)
        let record = try await store.createProof(for: data, label: "unit-test", mediaUTType: "public.data")

        let ok = try await store.verify(data: data)
        XCTAssertTrue(ok.isValid)
        XCTAssertEqual(ok.matchedRecord?.id, record.id)

        let bad = try await store.verify(data: Data("different".utf8))
        XCTAssertFalse(bad.isValid)
    }
}

