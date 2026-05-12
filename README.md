# KU Lost & Found

A SwiftUI iOS app for **Kasetsart University** that helps students report and recover lost items on campus. Built as a Year 4 Mobile Development project.
## Team

- **Sai Khun Main** -6510545373
- **Peerawat Theerasakul** -6610545880
## Features

- **Home** — Search and filter recent lost / found items by status and category, with quick-action shortcuts to report.
- **Explore** — MapKit view of the KU Bang Khen campus with pins for active reports; tap a pin to preview the item.
- **Browse** — Full filterable item catalogue.
- **Report** — Multi-step form to file a Lost or Found report (photo, item name, date, location, description, category) with a success confirmation.
- **Item Detail** — Full item view with hero image, metadata, description, and Claim / "I found this" CTA.
- **My Items** — Personal feed of the user's own reports, grouped by location.
- **Profile** — User stats (reported / returned / helped), recent reports, and settings.

## Tech Stack

**Language & UI**
- Swift 5 / SwiftUI
- MapKit — campus map with pin annotations (`ExploreScreen`)
- Min iOS: 17+ (uses `Map(position:)`, `.presentationDetents`, `@Observable`)
- Xcode 16+ (synchronized file system groups)
- Fonts: [Sarabun](https://fonts.google.com/specimen/Sarabun) (bundled — Light, Regular, Medium, SemiBold, Bold; supports Thai + Latin)

**Backend — Supabase**
- **Supabase Auth (GoTrue)** — Email/password sign-up & sign-in, Google OAuth via deep link (`ku-lost-found://auth-callback`), email confirmation flow, JWT session persisted in device keychain, restored on launch via `supabase.auth.session`
- **Supabase Database (PostgreSQL via PostgREST)** — All structured data; queried with the chainable Swift SDK (`.from().select().eq().order()`); results decoded directly into `Codable` Swift structs
- **Supabase Storage** — Item photos stored in the `item-photos` bucket; public URLs resolved via `getPublicURL(path:)`
- **Row Level Security (RLS)** — PostgreSQL policies enforce per-user access at the database level; the app communicates directly with Supabase using the publishable anon key

**State Management**
- `@Observable` (Swift 5.9 Observation framework) — `AuthViewModel`, `ItemsViewModel`, `NotificationsViewModel`
- No third-party state library

**No external Swift package dependencies** — Supabase Swift SDK is the only dependency; fonts are bundled and registered at startup via `CTFontManagerRegisterFontsForURL`

---

## Database Schema

All tables live in a Supabase (PostgreSQL) project. Row Level Security is enabled on every table.

### `profiles`
Mirrors `auth.users` — created automatically on sign-up via a database trigger.

| Column | Type | Notes |
|---|---|---|
| `id` | uuid PK | = `auth.users.id` |
| `full_name` | text | |
| `email` | text | |
| `phone` | text | nullable |
| `instagram` | text | nullable |
| `line_id` | text | nullable |

### `items`
Every lost or found report.

| Column | Type | Notes |
|---|---|---|
| `id` | uuid PK | |
| `reporter_id` | uuid FK → profiles | |
| `title` | text | |
| `emoji` | text | user-picked icon |
| `status` | enum | `lost` `found` `claimed` `expired` `returned` |
| `category` | enum | `electronics` `clothing` `id_card` `keys` `bag` `books` `other` |
| `description` | text | |
| `location_name` | text | human-readable location |
| `lat` | float8 | nullable |
| `lng` | float8 | nullable |
| `occurred_at` | timestamptz | when item was lost/found |
| `created_at` | timestamptz | when report was filed |
| `hint_question` | text | nullable — secret Q for claim verification |
| `returned_at` | timestamptz | nullable |

### `item_photos`
One-to-many with `items`.

| Column | Type | Notes |
|---|---|---|
| `item_id` | uuid FK → items | |
| `storage_path` | text | path in `item-photos` Storage bucket |

### `claims`
A user asserting ownership of a found item, or offering to return a lost one.

| Column | Type | Notes |
|---|---|---|
| `id` | uuid PK | |
| `item_id` | uuid FK → items | |
| `claimer_id` | uuid FK → profiles | |
| `message` | text | nullable |
| `state` | enum | `pending` `approved` `rejected` `withdrawn` |
| `created_at` | timestamptz | |

### `notifications`
Per-user in-app notification feed. Rows are inserted server-side by database triggers on claim events.

| Column | Type | Notes |
|---|---|---|
| `id` | uuid PK | |
| `user_id` | uuid FK → profiles | recipient |
| `actor_id` | uuid FK → profiles | who triggered the notification |
| `item_id` | uuid FK → items | nullable |
| `kind` | enum | `claim_submitted` `claim_approved` `claim_rejected` `sighting_added` |
| `read_at` | timestamptz | nullable — null = unread |
| `created_at` | timestamptz | |

### Entity Relationships

```
profiles ──< items ──< item_photos
                  ──< claims >── profiles (claimer)
notifications >── profiles (recipient)
              >── profiles (actor)
              >── items
```

## Project Structure

```
ku-lost&found/
├── ku_lost_foundApp.swift        # App entry — registers fonts, launches RootView
├── ContentView.swift
├── Theme/
│   └── KUTheme.swift             # Colors, radii, shadows, font registration
├── Models/
│   ├── Item.swift                # Item, ItemStatus, ItemCategory
│   └── SampleData.swift          # In-memory sample items + KU coordinates
├── Components/
│   ├── StatusBadge.swift         # Found / Lost / Claimed pill
│   ├── ItemCard.swift            # Row card with thumb, title, location, badge
│   ├── SectionHeader.swift
│   ├── PrimaryButton.swift
│   ├── KUSearchBar.swift
│   ├── Chips.swift               # StatusPill + CategoryChip
│   ├── QuickActionCard.swift     # "I lost / I found" tiles
│   └── LostFoundLogo.swift
├── Screens/
│   ├── RootView.swift            # 4-tab bar + centered Report FAB
│   ├── HomeScreen.swift
│   ├── ExploreScreen.swift
│   ├── BrowseScreen.swift
│   ├── ReportScreen.swift
│   ├── ItemDetailScreen.swift
│   ├── ProfileScreen.swift
│   └── MyItemsScreen.swift
└── Resources/
    └── Fonts/                    # Sarabun-Light / Regular / Medium / SemiBold / Bold
```

## Design System

Colors and tokens are centralized in [`Theme/KUTheme.swift`](ku-lost&found/Theme/KUTheme.swift).

- **Primary (Found / CTA):** KU Green `#006765`
- **Accent (Lost / destructive):** Red `#C62828`
- **Foundation:** White `#FFFFFF` / Near-black `#0A0A0A`
- **Surfaces:** Off-white `#F7F7F8` with 1px hairline borders (`#E5E5E7`)
- **Radii:** 6 / 8 / 10 (button) / 12 (card) / 16 / 999 (pill)
- **Typography:** Sarabun (Light → Bold)

The visual language follows an editorial / official aesthetic — clean white backgrounds, black text, sparing use of red and green for status semantics only.

## Getting Started

1. Clone the repository.
2. Open `ku-lost&found.xcodeproj` in Xcode 16 or newer.
3. Select an iPhone simulator (iPhone 15 / iOS 17+).
4. Press `⌘R` to build and run.

No external dependencies — Sarabun fonts are bundled and registered at startup via `CTFontManagerRegisterFontsForURL`.

## Branches

- `main` — base project + this README.
- `feat/ios-ui` — full UI implementation of the design handoff (7 screens + theme refactor).

## Design Source

The UI is based on a design handoff bundle from Claude Design (HTML/JSX prototypes). See the `feat/ios-ui` branch for the SwiftUI implementation.

## Author

Sai Khun Main · Year 4, Faculty of Engineering, Kasetsart University

## License

Educational project — not licensed for redistribution.
