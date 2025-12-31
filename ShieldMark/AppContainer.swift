import Foundation

@MainActor
final class AppContainer: ObservableObject {
    let keychain: KeychainStore
    let incidentLogger: IncidentLogger
    let lockdown: LockdownStateMachine
    let proofStore: ProofStore
    let vaultStore: VaultStore

    init() {
        // One service name for app secrets (keys, lockdown state, trusted devices).
        let keychain = KeychainStore(service: "com.example.ShieldMark")
        self.keychain = keychain

        do {
            let incidentLogger = try IncidentLogger()
            self.incidentLogger = incidentLogger
            self.lockdown = LockdownStateMachine(keychain: keychain, incidentLogger: incidentLogger)
            self.proofStore = try ProofStore(
                hasher: ProofHasher(),
                signer: CryptoSigner(keychain: keychain),
                incidentLogger: incidentLogger,
                signingAlgorithm: .ed25519
            )
            self.vaultStore = try VaultStore(keychain: keychain, lockdown: lockdown)
        } catch {
            fatalError("ShieldMark failed to initialize: \(error)")
        }
    }
}

