# ROLA

**Your AI relationship copilot for macOS.**

ROLA helps you stay connected by reducing the mental burden of replying to everyday messages. It drafts responses that sound exactly like you — while keeping you in full control.

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15.0 or later
- Swift 6.0

## Getting Started

1. Clone the repository
2. Open `ROLA.xcodeproj` in Xcode
3. Select the **ROLA** scheme and press **⌘R** to run

## Milestone 5 — What's Included

- **EventKit integration** — fetch events for the next 7 days
- **Availability checker** — free windows and busy/conflict detection
- **Scheduling detector** — recognizes planning language in messages
- **Calendar dashboard** — today + week view with free windows
- **Conversation hints** — calendar context banner on scheduling messages
- **AI context assembler** — natural-language calendar summary for Milestone 6

## Milestone 4 — What's Included

- **Style analysis engine** — heuristics for word length, emoji, lowercase, slang, greetings, sign-offs
- **Global profile** — your overall communication style from sent messages
- **Per-contact profiles** — relationship-specific tone (family, friends, work)
- **Your Style dashboard** — full communication profile view
- **Onboarding integration** — style analysis runs automatically after message import
- **Disk cache** — profiles persist across app launches

## Milestone 3 — What's Included

- **iMessage import** — read-only SQLite access to `~/Library/Messages/chat.db`
- **Conversation list** — threads sorted by recency with needs-reply detection
- **Message preview** — tap a conversation to see recent messages
- **Disk cache** — conversations cached in Application Support for fast reload
- **Dashboard refresh** — re-import button in header

## Milestone 2 — What's Included

- **Full Disk Access detection** — probes iMessage `chat.db` readability
- **Contacts** — `CNContactStore` request + status
- **Calendar** — `EKEventStore` full access request + status
- **Notifications** — `UNUserNotificationCenter` request + status
- **Live refresh** — permission status updates when returning from System Settings
- **FDA guide sheet** — step-by-step instructions with deep link to System Settings
- Sandbox entitlements + privacy usage descriptions

## Milestone 1 — What's Included

- Native SwiftUI macOS app shell (`com.rola.app`)
- Dark-mode-first design system
- Onboarding flow: Welcome → Privacy → Permissions → Import
- Placeholder dashboard with empty state
- Settings screen with OpenAI API key storage (Keychain)
- Protocol-oriented service layer with mock implementations
- Dependency injection container

## OpenAI API Key Strategy

ROLA uses a **bring-your-own-key** model for MVP:

- Users enter their OpenAI API key in **Settings**
- Keys are stored in the **macOS Keychain** — never uploaded
- This keeps costs with the user, maximizes privacy, and avoids backend key management in early milestones

## Project Structure

```
ROLA/
├── App/              # Entry point, app state, DI
├── Views/            # Onboarding, Dashboard, Settings
├── Components/       # Reusable UI components
├── Models/           # Data models and enums
├── ViewModels/       # MVVM view models
├── Services/         # Protocol definitions + mocks
├── Permissions/      # Permission manager
├── Utilities/        # Theme, Keychain
└── Assets.xcassets/  # Colors, icons
```

## Architecture

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the full system design.

## Development Roadmap

| Milestone | Status |
|-----------|--------|
| M1 — App shell + onboarding UI | ✅ Complete |
| M2 — Real permissions | ✅ Complete |
| M3 — iMessage import | ✅ Complete |
| M4 — Style analysis | ✅ Complete |
| M5 — Calendar integration | ✅ Current |
| M6 — AI pipeline | Planned |
| M7 — Learning + Supabase | Planned |
| M8 — Polish + notifications | Planned |

## Regenerating the Xcode Project

If you modify `project.yml` and have [XcodeGen](https://github.com/yonaskolb/XcodeGen) installed:

```bash
xcodegen generate
```

Alternatively, run:

```bash
python3 scripts/generate_xcodeproj.py
```

## License

Copyright © 2026 ROLA. All rights reserved.
