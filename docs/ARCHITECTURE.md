# ROLA — System Architecture

> AI Relationship Copilot for macOS  
> Version: MVP Architecture v0.1

---

## Executive Summary

ROLA is a **local-first macOS client** with a **cloud-backed personalization layer**. The core trust contract: iMessage content stays on-device; only derived style profiles and user-approved learning signals sync to the backend.

```
┌─────────────────────────────────────────────────────────────────┐
│                     macOS Application (SwiftUI)                  │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────────┐  │
│  │ Onboard  │ │Dashboard │ │ Suggest  │ │ Permissions Mgr  │  │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────────┬─────────┘  │
│       │            │            │                 │              │
│  ┌────┴────────────┴────────────┴─────────────────┴──────────┐  │
│  │                    Service Layer (Protocols)               │  │
│  │  MessageImport · StyleEngine · AIPipeline · Calendar      │  │
│  └────┬────────────┬────────────┬─────────────────┬──────────┘  │
│       │            │            │                 │              │
│  ┌────┴─────┐ ┌────┴─────┐ ┌───┴────┐    ┌──────┴──────┐       │
│  │ Local DB │ │ Keychain │ │EventKit│    │ CNContact   │       │
│  │(SwiftData│ │          │ │        │    │ Store       │       │
│  │ + GRDB)  │ │          │ │        │    │             │       │
│  └────┬─────┘ └──────────┘ └────────┘    └─────────────┘       │
│       │                                                          │
│  ┌────┴──────────────────────────────────────────────────────┐  │
│  │ ~/Library/Messages/chat.db  (read-only, Full Disk Access) │  │
│  └───────────────────────────────────────────────────────────┘  │
└────────────────────────────┬────────────────────────────────────┘
                             │ HTTPS (auth + derived profiles only)
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                         Supabase                                 │
│  Auth · PostgreSQL · pgvector · Storage · Edge Functions        │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    OpenAI Responses API                          │
│                    OpenAI Embeddings                             │
└─────────────────────────────────────────────────────────────────┘
```

---

## Core Architectural Principles

| Principle | Decision |
|-----------|----------|
| **Local-first** | Raw messages never leave the device |
| **Trust by default** | No auto-send in v1; human approves every reply |
| **Protocol-oriented** | All services behind protocols for testing & swapping |
| **Incremental sync** | Only style profiles, feedback signals, and embeddings sync |
| **Fail safe** | Safety classifier blocks low-confidence / sensitive topics |
| **Runnable milestones** | Each phase ships a working, testable app state |

---

## Folder Structure

```
ROLA/
├── App/
│   ├── ROLAApp.swift              # @main entry, DI container
│   ├── AppState.swift             # Global navigation & onboarding state
│   └── DependencyContainer.swift  # Service wiring
├── Views/
│   ├── Onboarding/
│   ├── Dashboard/
│   └── Settings/
├── Components/
│   ├── SuggestionCard.swift
│   ├── ConfidenceBadge.swift
│   ├── InboxHealthRing.swift
│   └── ...
├── Models/
│   ├── Message.swift
│   ├── Conversation.swift
│   ├── Contact.swift
│   ├── Suggestion.swift
│   ├── StyleProfile.swift
│   └── RelationshipProfile.swift
├── ViewModels/
│   ├── OnboardingViewModel.swift
│   ├── DashboardViewModel.swift
│   └── SuggestionViewModel.swift
├── Services/
│   ├── MessageImport/
│   ├── StyleAnalysis/
│   ├── Calendar/
│   ├── Contacts/
│   └── Notifications/
├── AI/
│   ├── Pipeline/
│   ├── Prompts/
│   ├── Safety/
│   └── OpenAIClient.swift
├── Database/
│   ├── Local/                     # SwiftData models + GRDB reader
│   └── Supabase/                  # Remote sync client
├── Permissions/
│   └── PermissionManager.swift
├── Utilities/
└── Assets/
```

---

## Data Flow: AI Pipeline

```
Incoming Message (from chat.db poll or manual refresh)
        │
        ▼
┌───────────────────┐
│ Classify Message  │  urgency · topic · relationship type
└────────┬──────────┘
         │
         ▼
┌───────────────────┐
│ Safety Pre-check  │  block emergencies, medical, legal, etc.
└────────┬──────────┘
         │ pass
         ▼
┌───────────────────┐
│ Gather Context    │
│ · last N messages │
│ · style profile   │
│ · relationship    │
│ · calendar window │
│ · time of day     │
└────────┬──────────┘
         │
         ▼
┌───────────────────┐
│ Generate Reply    │  OpenAI Responses API + structured output
└────────┬──────────┘
         │
         ▼
┌───────────────────┐
│ Safety Post-check │  confidence + content policy
└────────┬──────────┘
         │
         ▼
┌───────────────────┐
│ Present Suggestion│  Approve · Edit · Dismiss
└────────┬──────────┘
         │
         ▼
┌───────────────────┐
│ Learning Loop     │  diff approved/edited → update profiles
└───────────────────┘
```

---

## Local Data Model

### SwiftData (app-owned data)
- `CachedConversation` — metadata, last message, unread state
- `CachedMessage` — denormalized copy for fast UI (not full history)
- `SuggestionRecord` — pending/approved/dismissed suggestions
- `StyleProfile` — per-user and per-contact derived traits
- `UserFeedback` — edit diffs for continuous learning

### GRDB (read-only external)
- Reads `chat.db` via Full Disk Access
- Maps Apple schema (`message`, `chat`, `handle`, `chat_message_join`)
- Never writes to Apple's database

---

## Backend Schema (Supabase / PostgreSQL)

```sql
-- Users managed by Supabase Auth

profiles (
  id uuid PK references auth.users,
  display_name text,
  onboarding_complete boolean,
  created_at timestamptz
)

style_profiles (
  id uuid PK,
  user_id uuid FK,
  scope text,           -- 'global' | 'contact:{id}'
  traits jsonb,         -- vocabulary, emoji_rate, avg_length, etc.
  updated_at timestamptz
)

feedback_events (
  id uuid PK,
  user_id uuid FK,
  suggestion_id uuid,
  original_text text,
  final_text text,
  action text,          -- 'approved' | 'edited' | 'dismissed'
  created_at timestamptz
)

message_embeddings (
  id uuid PK,
  user_id uuid FK,
  contact_hash text,    -- hashed identifier, not raw phone
  embedding vector(1536),
  metadata jsonb,
  created_at timestamptz
)
```

---

## Security & Privacy

1. **Full Disk Access** — required for iMessage; explained clearly in onboarding
2. **Keychain** — OpenAI API key, Supabase tokens
3. **No raw message upload** — only derived profiles and anonymized feedback
4. **Contact hashing** — phone numbers hashed before any cloud storage
5. **Safety gate** — sensitive topics always require human review
6. **Sandbox** — app uses hardened runtime; entitlements documented in `ROLA.entitlements`

---

## Dependency Injection

```swift
protocol DependencyContainerProtocol {
    var messageImportService: MessageImportServiceProtocol { get }
    var styleEngine: StyleEngineProtocol { get }
    var aiPipeline: AIPipelineProtocol { get }
    var calendarService: CalendarServiceProtocol { get }
    var permissionManager: PermissionManagerProtocol { get }
}
```

Production container wires real services; `PreviewContainer` and `TestContainer` use mocks.

---

## Observability (Post-MVP wiring)

| Tool | Purpose | When |
|------|---------|------|
| PostHog | Product analytics, funnels | Milestone 6+ |
| Sentry | Crash & error monitoring | Milestone 6+ |

Deferred intentionally — core loop must work first.

---

## Known Constraints & Risks

| Risk | Mitigation |
|------|------------|
| No public iMessage API | Read `chat.db` with FDA; document fragility |
| Apple TOS ambiguity | Position as personal productivity tool; no auto-send |
| `chat.db` schema changes | Version-detect schema; graceful degradation |
| OpenAI latency | Show skeleton UI; cache recent suggestions |
| Style cold-start | Require minimum N messages before generating |

---

## Testing Strategy

- **Unit tests**: Services, AI safety rules, style analysis heuristics
- **Integration tests**: GRDB reader against fixture `chat.db`
- **UI tests**: Onboarding flow, suggestion approve/edit/dismiss
- **Snapshot tests**: Dashboard components (dark mode first)

---

## Milestone Roadmap

| # | Milestone | Outcome |
|---|-----------|---------|
| **M1** | App shell + onboarding UI | Runnable macOS app, welcome → permissions screens (UI only) |
| **M2** | Permissions + FDA detection | Real permission requests, status tracking |
| **M3** | iMessage import | Read chat.db, display conversations in dashboard |
| **M4** | Style analysis (local) | Generate communication profile from history |
| **M5** | Calendar integration | EventKit availability in context |
| **M6** | AI pipeline + suggestions | OpenAI generation, confidence, approve/edit/dismiss |
| **M7** | Learning loop + Supabase sync | Feedback updates profiles, cloud backup |
| **M8** | Polish + notifications | Native notifications, empty states, animations |

Each milestone = working app + PR.
