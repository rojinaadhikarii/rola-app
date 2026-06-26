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
| M2 — Real permissions | ✅ Current |
| M3 — iMessage import | Planned |
| M4 — Style analysis | Planned |
| M5 — Calendar integration | Planned |
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
