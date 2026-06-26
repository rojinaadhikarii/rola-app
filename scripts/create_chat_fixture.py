#!/usr/bin/env python3
"""Create a minimal chat.db fixture for unit tests."""

import os
import sqlite3

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FIXTURE_PATH = os.path.join(ROOT, "ROLATests", "Fixtures", "chat_fixture.db")

SCHEMA = """
CREATE TABLE chat (
    ROWID INTEGER PRIMARY KEY,
    guid TEXT,
    chat_identifier TEXT,
    display_name TEXT,
    service_name TEXT,
    style INTEGER
);
CREATE TABLE handle (
    ROWID INTEGER PRIMARY KEY,
    id TEXT,
    service TEXT
);
CREATE TABLE message (
    ROWID INTEGER PRIMARY KEY,
    guid TEXT,
    text TEXT,
    attributedBody BLOB,
    handle_id INTEGER,
    date INTEGER,
    is_from_me INTEGER,
    date_read INTEGER
);
CREATE TABLE chat_message_join (
    chat_id INTEGER,
    message_id INTEGER
);
CREATE TABLE chat_handle_join (
    chat_id INTEGER,
    handle_id INTEGER
);
"""

def main():
    os.makedirs(os.path.dirname(FIXTURE_PATH), exist_ok=True)
    if os.path.exists(FIXTURE_PATH):
        os.remove(FIXTURE_PATH)

    conn = sqlite3.connect(FIXTURE_PATH)
    conn.executescript(SCHEMA)

    # Nanoseconds since 2001-01-01 for a recent-ish date
    now_ns = 700_000_000_000_000_000

    conn.execute("INSERT INTO handle (ROWID, id, service) VALUES (1, '+15551234567', 'iMessage')")
    conn.execute("INSERT INTO handle (ROWID, id, service) VALUES (2, '+15559876543', 'iMessage')")

    conn.execute(
        "INSERT INTO chat (ROWID, guid, chat_identifier, display_name, service_name, style) "
        "VALUES (1, 'chat-1', '+15551234567', NULL, 'iMessage', 0)"
    )
    conn.execute(
        "INSERT INTO chat (ROWID, guid, chat_identifier, display_name, service_name, style) "
        "VALUES (2, 'chat-2', '+15559876543', 'Mom', 'iMessage', 0)"
    )

    conn.execute("INSERT INTO chat_handle_join (chat_id, handle_id) VALUES (1, 1)")
    conn.execute("INSERT INTO chat_handle_join (chat_id, handle_id) VALUES (2, 2)")

    conn.execute(
        "INSERT INTO message (ROWID, guid, text, handle_id, date, is_from_me, date_read) "
        "VALUES (1, 'msg-1', 'Are you free Thursday?', 1, ?, 0, 0)",
        (now_ns,),
    )
    conn.execute(
        "INSERT INTO message (ROWID, guid, text, handle_id, date, is_from_me, date_read) "
        "VALUES (2, 'msg-2', 'Yep! Just got home', 2, ?, 0, 0)",
        (now_ns - 3_600_000_000_000,),
    )
    conn.execute(
        "INSERT INTO message (ROWID, guid, text, handle_id, date, is_from_me, date_read) "
        "VALUES (3, 'msg-3', 'Great to hear!', 0, ?, 1, ?)",
        (now_ns - 1_800_000_000_000, now_ns - 1_800_000_000_000),
    )

    conn.execute("INSERT INTO chat_message_join (chat_id, message_id) VALUES (1, 1)")
    conn.execute("INSERT INTO chat_message_join (chat_id, message_id) VALUES (1, 3)")
    conn.execute("INSERT INTO chat_message_join (chat_id, message_id) VALUES (2, 2)")

    outgoing_messages = [
        (4, "hey! yeah i'm down 😂", 1, now_ns - 5_400_000_000_000),
        (5, "sounds good, see you then", 1, now_ns - 5_000_000_000_000),
        (6, "lol for real", 1, now_ns - 4_800_000_000_000),
        (7, "hey want to grab dinner?", 1, now_ns - 4_600_000_000_000),
        (8, "i'm free after 6", 1, now_ns - 4_400_000_000_000),
        (9, "perfect thanks!", 1, now_ns - 4_200_000_000_000),
        (10, "yep! just got home ❤️", 2, now_ns - 3_800_000_000_000),
        (11, "love you!", 2, now_ns - 3_600_000_000_000),
        (12, "hey mom", 2, now_ns - 3_400_000_000_000),
        (13, "ok sounds good", 2, now_ns - 3_200_000_000_000),
        (14, "on my way home now", 2, now_ns - 3_000_000_000_000),
        (15, "thanks!", 1, now_ns - 2_800_000_000_000),
    ]

    for rowid, text, chat_id, date in outgoing_messages:
        conn.execute(
            "INSERT INTO message (ROWID, guid, text, handle_id, date, is_from_me, date_read) "
            "VALUES (?, ?, ?, 0, ?, 1, ?)",
            (rowid, f"msg-{rowid}", text, date, date),
        )
        conn.execute(
            "INSERT INTO chat_message_join (chat_id, message_id) VALUES (?, ?)",
            (chat_id, rowid),
        )

    conn.commit()
    conn.close()
    print(f"Created {FIXTURE_PATH}")


if __name__ == "__main__":
    main()
