import Foundation
import SQLite3

// MARK: - Raw Rows

struct RawConversationRow: Sendable {
    let chatId: Int64
    let guid: String?
    let chatIdentifier: String?
    let displayName: String?
    let serviceName: String?
    let style: Int
    let lastMessageId: Int64?
    let lastMessageText: String?
    let lastAttributedBody: Data?
    let lastMessageDate: Int64?
    let lastMessageIsFromMe: Bool
    let lastMessageDateRead: Int64?
    let participantHandles: [String]
}

struct RawMessageRow: Sendable {
    let messageId: Int64
    let chatId: Int64
    let text: String?
    let attributedBody: Data?
    let date: Int64
    let isFromMe: Bool
    let handleIdentifier: String?
}

// MARK: - Chat DB Reader

/// Read-only access to Apple's iMessage SQLite database.
final class ChatDBReader: @unchecked Sendable {

    let databasePath: String

    init(databasePath: String = FullDiskAccessChecker.messagesDatabasePath) {
        self.databasePath = databasePath
    }

    func fetchConversations(limit: Int = 500) throws -> [RawConversationRow] {
        guard FullDiskAccessChecker.canReadMessagesDatabase(at: databasePath) else {
            throw ChatDBError.fullDiskAccessRequired
        }

        guard FileManager.default.fileExists(atPath: databasePath) else {
            throw ChatDBError.databaseNotFound(path: databasePath)
        }

        var database: OpaquePointer?
        guard sqlite3_open_v2(databasePath, &database, SQLITE_OPEN_READONLY, nil) == SQLITE_OK,
              let database
        else {
            let message = String(cString: sqlite3_errmsg(database))
            sqlite3_close(database)
            throw ChatDBError.openFailed(message: message)
        }
        defer { sqlite3_close(database) }

        let sql = """
            SELECT
                c.ROWID,
                c.guid,
                c.chat_identifier,
                c.display_name,
                c.service_name,
                c.style,
                lm.message_id,
                lm.text,
                lm.attributedBody,
                lm.date,
                lm.is_from_me,
                lm.date_read
            FROM chat c
            LEFT JOIN (
                SELECT
                    cmj.chat_id,
                    m.ROWID AS message_id,
                    m.text,
                    m.attributedBody,
                    m.date,
                    m.is_from_me,
                    m.date_read,
                    ROW_NUMBER() OVER (PARTITION BY cmj.chat_id ORDER BY m.date DESC) AS rn
                FROM chat_message_join cmj
                JOIN message m ON m.ROWID = cmj.message_id
            ) lm ON lm.chat_id = c.ROWID AND lm.rn = 1
            WHERE c.service_name IN ('iMessage', 'SMS', 'RCS')
            ORDER BY lm.date DESC
            LIMIT ?
            """

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK,
              let statement
        else {
            throw ChatDBError.queryFailed(message: errorMessage(from: database))
        }
        defer { sqlite3_finalize(statement) }

        sqlite3_bind_int(statement, 1, Int32(limit))

        var rows: [RawConversationRow] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            let chatId = sqlite3_column_int64(statement, 0)
            let handles = try fetchParticipantHandles(chatId: chatId, database: database)

            rows.append(
                RawConversationRow(
                    chatId: chatId,
                    guid: columnOptionalString(statement, index: 1),
                    chatIdentifier: columnOptionalString(statement, index: 2),
                    displayName: columnOptionalString(statement, index: 3),
                    serviceName: columnOptionalString(statement, index: 4),
                    style: Int(sqlite3_column_int(statement, 5)),
                    lastMessageId: sqlite3_column_type(statement, 6) == SQLITE_NULL
                        ? nil : sqlite3_column_int64(statement, 6),
                    lastMessageText: columnOptionalString(statement, index: 7),
                    lastAttributedBody: columnOptionalData(statement, index: 8),
                    lastMessageDate: sqlite3_column_type(statement, 9) == SQLITE_NULL
                        ? nil : sqlite3_column_int64(statement, 9),
                    lastMessageIsFromMe: sqlite3_column_int(statement, 10) == 1,
                    lastMessageDateRead: sqlite3_column_type(statement, 11) == SQLITE_NULL
                        ? nil : sqlite3_column_int64(statement, 11),
                    participantHandles: handles
                )
            )
        }

        return rows
    }

    func fetchRecentMessages(chatId: Int64, limit: Int = 40) throws -> [RawMessageRow] {
        guard FullDiskAccessChecker.canReadMessagesDatabase(at: databasePath) else {
            throw ChatDBError.fullDiskAccessRequired
        }

        var database: OpaquePointer?
        guard sqlite3_open_v2(databasePath, &database, SQLITE_OPEN_READONLY, nil) == SQLITE_OK,
              let database
        else {
            let message = String(cString: sqlite3_errmsg(database))
            sqlite3_close(database)
            throw ChatDBError.openFailed(message: message)
        }
        defer { sqlite3_close(database) }

        let sql = """
            SELECT
                m.ROWID,
                cmj.chat_id,
                m.text,
                m.attributedBody,
                m.date,
                m.is_from_me,
                h.id
            FROM chat_message_join cmj
            JOIN message m ON m.ROWID = cmj.message_id
            LEFT JOIN handle h ON h.ROWID = m.handle_id
            WHERE cmj.chat_id = ?
            ORDER BY m.date DESC
            LIMIT ?
            """

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK,
              let statement
        else {
            throw ChatDBError.queryFailed(message: errorMessage(from: database))
        }
        defer { sqlite3_finalize(statement) }

        sqlite3_bind_int64(statement, 1, chatId)
        sqlite3_bind_int(statement, 2, Int32(limit))

        var rows: [RawMessageRow] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            rows.append(
                RawMessageRow(
                    messageId: sqlite3_column_int64(statement, 0),
                    chatId: sqlite3_column_int64(statement, 1),
                    text: columnOptionalString(statement, index: 2),
                    attributedBody: columnOptionalData(statement, index: 3),
                    date: sqlite3_column_int64(statement, 4),
                    isFromMe: sqlite3_column_int(statement, 5) == 1,
                    handleIdentifier: columnOptionalString(statement, index: 6)
                )
            )
        }

        return rows.reversed()
    }

    // MARK: - Private

    private func fetchParticipantHandles(chatId: Int64, database: OpaquePointer) throws -> [String] {
        let sql = """
            SELECT h.id
            FROM chat_handle_join chj
            JOIN handle h ON h.ROWID = chj.handle_id
            WHERE chj.chat_id = ?
            """

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK,
              let statement
        else {
            throw ChatDBError.queryFailed(message: errorMessage(from: database))
        }
        defer { sqlite3_finalize(statement) }

        sqlite3_bind_int64(statement, 1, chatId)

        var handles: [String] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            if let handle = columnOptionalString(statement, index: 0) {
                handles.append(handle)
            }
        }
        return handles
    }

    private func columnOptionalString(_ statement: OpaquePointer, index: Int32) -> String? {
        guard sqlite3_column_type(statement, index) != SQLITE_NULL,
              let cString = sqlite3_column_text(statement, index)
        else { return nil }
        return String(cString: cString)
    }

    private func columnOptionalData(_ statement: OpaquePointer, index: Int32) -> Data? {
        guard sqlite3_column_type(statement, index) != SQLITE_NULL else { return nil }
        let bytes = sqlite3_column_blob(statement, index)
        let count = Int(sqlite3_column_bytes(statement, index))
        guard let bytes, count > 0 else { return nil }
        return Data(bytes: bytes, count: count)
    }

    private func errorMessage(from database: OpaquePointer?) -> String {
        guard let database else { return "Unknown SQLite error" }
        return String(cString: sqlite3_errmsg(database))
    }
}

// MARK: - Row Mapping

extension Conversation {
    init(row: RawConversationRow) {
        let resolvedText = row.lastMessageText
            ?? AttributedBodyDecoder.decodeText(from: row.lastAttributedBody)

        let lastDate = row.lastMessageDate.flatMap(AppleDateConverter.date(fromAppleTimestamp:))
        let isGroup = row.participantHandles.count > 1
        let displayName = Conversation.resolveDisplayName(
            displayName: row.displayName,
            chatIdentifier: row.chatIdentifier,
            handles: row.participantHandles,
            isGroup: isGroup
        )

        let needsReply = row.lastMessageId != nil
            && !row.lastMessageIsFromMe
            && (row.lastMessageDateRead == nil || row.lastMessageDateRead == 0)

        self.init(
            id: row.chatId,
            guid: row.guid,
            displayName: displayName,
            participantHandles: row.participantHandles,
            serviceName: row.serviceName ?? "iMessage",
            isGroup: isGroup,
            lastMessageText: resolvedText,
            lastMessageDate: lastDate,
            lastMessageIsFromMe: row.lastMessageIsFromMe,
            needsReply: needsReply
        )
    }

    static func resolveDisplayName(
        displayName: String?,
        chatIdentifier: String?,
        handles: [String],
        isGroup: Bool
    ) -> String {
        if let displayName, !displayName.isEmpty {
            return displayName
        }
        if isGroup, let chatIdentifier, !chatIdentifier.isEmpty {
            return chatIdentifier
        }
        if let firstHandle = handles.first {
            return formatHandle(firstHandle)
        }
        if let chatIdentifier, !chatIdentifier.isEmpty {
            return formatHandle(chatIdentifier)
        }
        return "Unknown"
    }

    private static func formatHandle(_ handle: String) -> String {
        if handle.contains("@") {
            return handle
        }
        if handle.hasPrefix("+") {
            return handle
        }
        return handle
    }
}

extension ImportedMessage {
    init(row: RawMessageRow) {
        let resolvedText = row.text
            ?? AttributedBodyDecoder.decodeText(from: row.attributedBody)
            ?? ""

        self.init(
            id: row.messageId,
            chatId: row.chatId,
            text: resolvedText,
            date: AppleDateConverter.date(fromAppleTimestamp: row.date) ?? .distantPast,
            isFromMe: row.isFromMe,
            handleIdentifier: row.handleIdentifier
        )
    }
}
