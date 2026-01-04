import CryptoKit
import Foundation

/// Local vault with encryption-at-rest (AES-GCM). Symmetric key is stored in Keychain.
actor VaultStore {
    enum VaultError: Error, Equatable {
        case locked
        case itemNotFound
        case corruptCiphertext
    }

    private let keychain: KeychainStore
    private let lockdown: LockdownStateMachine

    private let vaultKeyAccount = "vault.symmetricKey"
    private let indexURL: URL
    private let blobsDir: URL

    private var index: [VaultItem] = []

    init(keychain: KeychainStore, lockdown: LockdownStateMachine) throws {
        self.keychain = keychain
        self.lockdown = lockdown

        let base = try AppPaths.applicationSupportDirectory()
        self.blobsDir = base.appendingPathComponent("VaultBlobs", isDirectory: true)
        self.indexURL = base.appendingPathComponent("vault_index.json", isDirectory: false)

        try AppPaths.ensureDirectory(blobsDir)
        self.index = (try? Self.loadIndex(from: indexURL)) ?? []
        _ = try getOrCreateVaultKey()
    }

    func listItems() async throws -> [VaultItem] {
        let state = await lockdown.state
        guard state.mode == .unlocked else { throw VaultError.locked }
        return index.sorted { $0.updatedAt > $1.updatedAt }
    }

    func putBlob(_ data: Data, title: String, kind: VaultItem.Kind = .blob) async throws -> VaultItem {
        let state = await lockdown.state
        guard state.mode == .unlocked else { throw VaultError.locked }

        let item = VaultItem(kind: kind, title: title, createdAt: Date(), updatedAt: Date(), reference: nil)
        let encrypted = try encrypt(data)
        let url = blobURL(for: item.id)
        try encrypted.write(to: url, options: [.atomic])

        var stored = item
        stored.reference = url.lastPathComponent
        index.append(stored)
        try persistIndex()
        return stored
    }

    func getBlob(itemID: UUID) async throws -> Data {
        let state = await lockdown.state
        guard state.mode == .unlocked else { throw VaultError.locked }

        guard let item = index.first(where: { $0.id == itemID }) else { throw VaultError.itemNotFound }
        let url = blobURL(for: item.id)
        let data = try Data(contentsOf: url)
        return try decrypt(data)
    }

    // MARK: - Crypto

    private func getOrCreateVaultKey() throws -> SymmetricKey {
        if let existing = try keychain.getIfPresent(account: vaultKeyAccount) {
            return SymmetricKey(data: existing)
        }
        let key = SymmetricKey(size: .bits256)
        let data = key.withUnsafeBytes { Data($0) }
        try keychain.set(data, account: vaultKeyAccount)
        return key
    }

    private func encrypt(_ plaintext: Data) throws -> Data {
        let key = try getOrCreateVaultKey()
        let sealed = try AES.GCM.seal(plaintext, using: key)
        // `combined` includes nonce + ciphertext + tag.
        guard let combined = sealed.combined else { throw VaultError.corruptCiphertext }
        return combined
    }

    private func decrypt(_ combined: Data) throws -> Data {
        let key = try getOrCreateVaultKey()
        guard let box = try? AES.GCM.SealedBox(combined: combined) else { throw VaultError.corruptCiphertext }
        return try AES.GCM.open(box, using: key)
    }

    // MARK: - Paths & persistence

    private func blobURL(for id: UUID) -> URL {
        blobsDir.appendingPathComponent("\(id.uuidString).bin", isDirectory: false)
    }

    private func persistIndex() throws {
        let data = try JSONEncoder().encode(index)
        try data.write(to: indexURL, options: [.atomic])
    }

    private static func loadIndex(from url: URL) throws -> [VaultItem] {
        let fm = FileManager.default
        guard fm.fileExists(atPath: url.path) else { return [] }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([VaultItem].self, from: data)
    }
}

