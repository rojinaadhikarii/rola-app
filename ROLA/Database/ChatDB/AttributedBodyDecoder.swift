import Foundation

// MARK: - Attributed Body Decoder

/// Decodes iMessage `attributedBody` blobs when the `text` column is empty.
enum AttributedBodyDecoder {

    static func decodeText(from data: Data?) -> String? {
        guard let data, !data.isEmpty else { return nil }

        if let attributed = try? NSAttributedString(
            data: data,
            options: [
                .documentType: NSAttributedString.DocumentType.rtfd,
                .characterEncoding: String.Encoding.utf8.rawValue,
            ],
            documentAttributes: nil
        ), !attributed.string.isEmpty {
            return attributed.string
        }

        if let attributed = try? NSKeyedUnarchiver.unarchivedObject(
            ofClass: NSAttributedString.self,
            from: data
        ), !attributed.string.isEmpty {
            return attributed.string
        }

        if let plain = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .controlCharacters),
           !plain.isEmpty {
            return plain
        }

        return nil
    }
}
