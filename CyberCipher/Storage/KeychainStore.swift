import Foundation
import Security

/// Minimal Keychain wrapper intended for app secrets (keys, vault material).
///
/// Notes:
/// - Uses `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` by default.
/// - Stores values as generic password items keyed by (service, account).
struct KeychainStore: Sendable {
    enum KeychainError: Error, Equatable {
        case unexpectedStatus(OSStatus)
        case itemNotFound
        case invalidItemFormat
    }

    let service: String

    init(service: String) {
        self.service = service
    }

    func set(_ data: Data, account: String, accessible: CFString = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly) throws {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: accessible,
        ]

        let statusUpdate = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if statusUpdate == errSecSuccess {
            return
        }

        if statusUpdate == errSecItemNotFound {
            query[kSecValueData as String] = data
            query[kSecAttrAccessible as String] = accessible
            let statusAdd = SecItemAdd(query as CFDictionary, nil)
            guard statusAdd == errSecSuccess else { throw KeychainError.unexpectedStatus(statusAdd) }
            return
        }

        throw KeychainError.unexpectedStatus(statusUpdate)
    }

    func get(account: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecItemNotFound {
            throw KeychainError.itemNotFound
        }
        guard status == errSecSuccess else { throw KeychainError.unexpectedStatus(status) }
        guard let data = item as? Data else { throw KeychainError.invalidItemFormat }
        return data
    }

    func getIfPresent(account: String) throws -> Data? {
        do {
            return try get(account: account)
        } catch let error as KeychainError where error == .itemNotFound {
            return nil
        }
    }

    func delete(account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]

        let status = SecItemDelete(query as CFDictionary)
        if status == errSecSuccess || status == errSecItemNotFound {
            return
        }
        throw KeychainError.unexpectedStatus(status)
    }

    func setCodable<T: Codable>(_ value: T, account: String, accessible: CFString = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly) throws {
        let data = try JSONEncoder().encode(value)
        try set(data, account: account, accessible: accessible)
    }

    func getCodable<T: Codable>(_ type: T.Type, account: String) throws -> T {
        let data = try get(account: account)
        return try JSONDecoder().decode(T.self, from: data)
    }
}

