import Foundation

// MARK: - Chat DB Error

enum ChatDBError: LocalizedError {
    case fullDiskAccessRequired
    case databaseNotFound(path: String)
    case openFailed(message: String)
    case queryFailed(message: String)
    case invalidData

    var errorDescription: String? {
        switch self {
        case .fullDiskAccessRequired:
            "Full Disk Access is required to read iMessage history."
        case .databaseNotFound(let path):
            "iMessage database not found at \(path)."
        case .openFailed(let message):
            "Could not open iMessage database: \(message)"
        case .queryFailed(let message):
            "Failed to read messages: \(message)"
        case .invalidData:
            "Unexpected data in iMessage database."
        }
    }
}

// MARK: - Message Import Error

enum MessageImportError: LocalizedError {
    case fullDiskAccessRequired
    case importFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .fullDiskAccessRequired:
            "Full Disk Access is required to import messages."
        case .importFailed(let underlying):
            underlying.localizedDescription
        }
    }
}
