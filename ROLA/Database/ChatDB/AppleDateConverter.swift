import Foundation

// MARK: - Apple Date Converter

/// Converts iMessage date values (seconds or nanoseconds since 2001-01-01) to `Date`.
enum AppleDateConverter {

    static func date(fromAppleTimestamp timestamp: Int64) -> Date? {
        guard timestamp > 0 else { return nil }

        let intervalSinceReference: TimeInterval
        if timestamp > 1_000_000_000_000 {
            intervalSinceReference = Double(timestamp) / 1_000_000_000
        } else {
            intervalSinceReference = Double(timestamp)
        }

        return Date(timeIntervalSinceReferenceDate: intervalSinceReference)
    }
}
