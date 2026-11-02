import Foundation
import Security

/// Minimal Keychain wrapper. Tokens never go to UserDefaults.
struct KeychainStore: Sendable {
    let service: String

    func save(_ data: Data, account: String) {
        let query = baseQuery(account: account)
        let status = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if status == errSecItemNotFound {
            var item = query
            item[kSecValueData as String] = data
            item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            SecItemAdd(item as CFDictionary, nil)
        }
    }

    func read(account: String) -> Data? {
        var query = baseQuery(account: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess else { return nil }
        return result as? Data
    }

    func delete(account: String) {
        SecItemDelete(baseQuery(account: account) as CFDictionary)
    }

    private func baseQuery(account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}

/// Persists the signed-in session between launches.
struct SessionStore: Sendable {
    private let keychain = KeychainStore(service: "com.alisherizmukhan.Lumen.session")
    private let account = "auth-session"

    func load() -> AuthSession? {
        keychain.read(account: account).flatMap { try? JSONDecoder().decode(AuthSession.self, from: $0) }
    }

    func save(_ session: AuthSession) {
        guard let data = try? JSONEncoder().encode(session) else { return }
        keychain.save(data, account: account)
    }

    func clear() {
        keychain.delete(account: account)
    }
}
