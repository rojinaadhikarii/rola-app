import Foundation
import Security

// MARK: - Keychain Helper

/// Secure storage for sensitive values (API keys, tokens).
enum KeychainHelper {

  enum Key: String {
    case openAIAPIKey = "com.rola.app.openai-api-key"
  }

  enum KeychainError: LocalizedError {
    case encodingFailed
    case unexpectedStatus(OSStatus)

    var errorDescription: String? {
      switch self {
      case .encodingFailed:
        "Failed to encode value for keychain storage."
      case .unexpectedStatus(let status):
        "Keychain operation failed with status \(status)."
      }
    }
  }

  static func save(_ value: String, for key: Key) throws {
    guard let data = value.data(using: .utf8) else {
      throw KeychainError.encodingFailed
    }

    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key.rawValue,
      kSecAttrService as String: "com.rola.app",
      kSecValueData as String: data,
    ]

    SecItemDelete(query as CFDictionary)

    let status = SecItemAdd(query as CFDictionary, nil)
    guard status == errSecSuccess else {
      throw KeychainError.unexpectedStatus(status)
    }
  }

  static func load(for key: Key) -> String? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key.rawValue,
      kSecAttrService as String: "com.rola.app",
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne,
    ]

    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)

    guard status == errSecSuccess,
          let data = result as? Data,
          let string = String(data: data, encoding: .utf8)
    else {
      return nil
    }

    return string
  }

  static func delete(for key: Key) {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key.rawValue,
      kSecAttrService as String: "com.rola.app",
    ]
    SecItemDelete(query as CFDictionary)
  }

  static func hasValue(for key: Key) -> Bool {
    load(for: key) != nil
  }
}
