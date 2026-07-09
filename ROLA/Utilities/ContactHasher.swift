import CryptoKit
import Foundation

// MARK: - Contact Hasher

/// Hashes contact identifiers before any cloud storage — raw phone numbers never leave the device.
enum ContactHasher {
    private static let salt = "com.rola.app.contact-hash.v1"

    static func hash(chatId: Int64) -> String {
        let input = "\(salt):\(chatId)"
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
