# KU Lost & Found

A SwiftUI iOS app for **Kasetsart University** that helps students report and recover lost items on campus. Built as a Year 4 Mobile Development project.
## Team

- **Sai Khun Main**
- **Peerawat Theerasakul**
## Features

- **Home** — Search and filter recent lost / found items by status and category, with quick-action shortcuts to report.
- **Explore** — MapKit view of the KU Bang Khen campus with pins for active reports; tap a pin to preview the item.
- **Browse** — Full filterable item catalogue.
- **Report** — Multi-step form to file a Lost or Found report (photo, item name, date, location, description, category) with a success confirmation.
- **Item Detail** — Full item view with hero image, metadata, description, and Claim / "I found this" CTA.
- **My Items** — Personal feed of the user's own reports, grouped by location.
- **Profile** — User stats (reported / returned / helped), recent reports, and settings.

## Tech Stack

- **Language:** Swift 5
- **UI:** SwiftUI
- **Maps:** MapKit
- **Min iOS:** 17+ (uses `Map(position:)`, `.presentationDetents`, etc.)
- **Fonts:** [Sarabun](https://fonts.google.com/specimen/Sarabun) (bundled, supports Thai + Latin)
- **Xcode:** 16+ (uses synchronized file system groups)

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
