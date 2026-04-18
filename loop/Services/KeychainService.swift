import Foundation
import Security

enum KeychainService {
    enum Error: Swift.Error {
        case saveFailed
        case readFailed
        case deleteFailed
    }

    private static let service = "com.niman.loop.claude-api"
    private static let account = "api-key"

    static func save(_ key: String) throws {
        guard let data = key.data(using: .utf8) else { throw Error.saveFailed }

        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]

        let existing = SecItemCopyMatching(query as CFDictionary, nil)

        if existing == errSecSuccess {
            let update: [CFString: Any] = [kSecValueData: data]
            let status = SecItemUpdate(query as CFDictionary, update as CFDictionary)
            guard status == errSecSuccess else { throw Error.saveFailed }
        } else if existing == errSecItemNotFound {
            var add = query
            add[kSecValueData] = data
            let status = SecItemAdd(add as CFDictionary, nil)
            guard status == errSecSuccess else { throw Error.saveFailed }
        } else {
            throw Error.saveFailed
        }
    }

    static func load() -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete() throws {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw Error.deleteFailed
        }
    }
}
