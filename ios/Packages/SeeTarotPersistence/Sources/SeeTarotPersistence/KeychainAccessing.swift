import Foundation
import Security

/// Seam over the Keychain so the token store is unit-testable with a fake
/// (the real Security API needs an entitled host).
public protocol KeychainAccessing: Sendable {
    func read(_ key: String) -> String?
    func write(_ key: String, _ value: String)
    func delete(_ key: String)
}

/// Real Keychain. Token-class generic password, device-only after first
/// unlock (no iCloud sync, survives lock).
public struct SystemKeychain: KeychainAccessing {
    private let service: String

    public init(service: String = "com.seetarot.app") { self.service = service }

    private func query(_ key: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: key]
    }

    public func read(_ key: String) -> String? {
        var q = query(key)
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        guard SecItemCopyMatching(q as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    public func write(_ key: String, _ value: String) {
        delete(key)
        var q = query(key)
        q[kSecValueData as String] = Data(value.utf8)
        q[kSecAttrAccessible as String] =
            kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(q as CFDictionary, nil)
    }

    public func delete(_ key: String) {
        SecItemDelete(query(key) as CFDictionary)
    }
}
