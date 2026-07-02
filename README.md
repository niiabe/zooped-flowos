<p align="center">
  <img src="assets/images/AppBar.png" alt="ZooPed Logo" width="200"/>
</p>

# ZooPed - Dog Pedigree Tracker

A Flutter Android application for tracking dog pedigrees, designed for professional breeders and kennel clubs.

**Package:** `com.zooped.niiabe` | **Version:** 1.7.0+14 | **License:** Private

## Platform

- **Android Only** - Built exclusively for Android devices
- **Responsive Design** - Adapts seamlessly to phones and tablets of all sizes

## Features

- **Dog Identity Ledger** - Register and manage dogs with call names, registered names, microchip numbers, breed, color, sale status, and more
- **Dog Photo Gallery** - Multiple photos per dog with captions and date ordering
- **Interactive 3-Generation Pedigree Tree** - Zoomable/pannable InteractiveViewer canvas displaying sire/dam lineage with tap-to-navigate to ancestors
- **3-Generation PDF Export** - Generate professional A4 landscape pedigree certificates for printing or sharing
- **Puppy Contract PDF** - Generate a Puppy Bill of Sale & Contract for buyers
- **Litter Tracking** - Record matings, whelping dates, and auto-create puppy profiles with inherited parentage
- **Health Records** - Track vaccines, deworming, vet visits with push notification reminders for upcoming due dates
- **Show Records** - Log event names, dates, judges, placements, and titles awarded
- **Mating Records** - Track sire/dam pairs with dates, used for whelping predictions
- **Heat Tracker** - Log and monitor female heat cycles with upcoming whelping alerts
- **Upcoming Agenda** - Combined view of predicted whelpings and next heat cycles, sorted chronologically
- **Matchmaker & COI Prediction** - Simulate breeding pairs with 5-generation inbreeding coefficient calculation
- **Kennel Analytics** - Dashboard with total dogs, male/female breakdown, litter stats, breed distribution
- **Financial Tracking** - Revenue/expense tracking by category with net profit/loss summary
- **Custom Kennel Branding** - Upload kennel logo and configure breeder profile (logo-driven theme)
- **CSV Backup & Restore** - Export and import all data as CSV files; local SQLite backup/restore
- **Dynamic Theming** - Switch between Dark/Light/System modes and multiple accent colors
- **Dashboard Search & Filter** - Search by name or microchip, filter by sex, sort by name/recent/age
- **Offline-First** - All data stored locally using SQLite via Drift

## Screenshots

| Dashboard | Pedigree Tree | Litter Form | Settings |
|-----------|--------------|-------------|----------|
| Search, dog list, quick-add | 3-gen interactive canvas | 3-step wizard | Profile, backup, branding |

## Tech Stack

| Layer | Technology |
|-------|------------|
| Platform | Android |
| Framework | Flutter |
| State Management | Riverpod |
| Navigation | go_router |
| Database | Drift (over SQLite) |
| PDF Generation | pdf + printing |
| Push Notifications | flutter_local_notifications |
| Image Picker | image_picker |
| URL Launcher | url_launcher |
| App Icon | flutter_launcher_icons |
| Splash Screen | flutter_native_splash |

## Branding

Logo-derived theme colors:
- **Primary** - Green (#3CB91A) from ZooPed logo
- **Secondary** - Dark Charcoal (#3D3D3D)
- **Background** - White

## Responsive Design

The app automatically adapts to different screen sizes:

| Screen Size | Behavior |
|-------------|----------|
| Small Phone (<375px) | Compact layout, smaller fonts/padding |
| Phone (375-599px) | Standard layout |
| Tablet (600-1023px) | Side-by-side panels, larger cards, grid views |
| Large Tablet (1024px+) | Expanded layouts, multi-column grids |

### Responsive Components
- **PedigreeCardNode** - Scales card dimensions (140-180dp width)
- **PedigreeCanvas** - Adjusts spacing and connector sizes
- **DashboardScreen** - Grid view on tablet, list on phone
- **DogDetailScreen** - Side-by-side on tablet, stacked on phone
- **LitterFormScreen** - Side-by-side fields on tablet
- **SettingsScreen** - Two-column layout on tablet

## Architecture

Clean Architecture with strict layer separation:

```
lib/
├── core/
│   ├── database/       # Drift database definition & tables
│   ├── router/         # go_router configuration (14 routes)
│   ├── services/       # certificate, contract, file_storage, notification
│   ├── theme/          # App theme (Green + Charcoal) & theme provider
│   ├── utils/          # Responsive utility
│   └── error/          # Error handler & exceptions
└── features/
    ├── pedigree/
    │   ├── domain/     # Entities (dog, litter), repository (abstract), use cases (COI)
    │   ├── data/       # Drift models, repository implementations
    │   └── presentation/ # 11 screens, 6 widgets, 2 providers
    └── settings/
        ├── domain/     # KennelProfile entity, repository (abstract), use cases
        ├── data/       # Repository implementation
        └── presentation/ # 6 screens, 1 provider
```

## Getting Started

### Prerequisites

- Flutter SDK 3.44.0+
- Dart SDK 3.12.0+

### Installation

```bash
# Clone the repository
git clone https://github.com/niiabe/zooped-flowos.git

# Navigate to project directory
cd zooped

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Code Generation

```bash
# Generate Drift database code
dart run build_runner build --delete-conflicting-outputs
```

### Build APK

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release
```

## Database Schema

### Tables

- **dogs** - Core dog records with self-referencing sire/dam foreign keys and sale status
- **dog_photos** - Multiple photos per dog with captions and timestamps
- **litters** - Breeding events linking sire/dam with whelping outcomes
- **health_records** - Vaccinations, deworming, vet visits with next due date tracking
- **show_records** - Event logs with dates, judges, placements, titles
- **transactions** - Kennel financial tracking (revenue/expenses by category)
- **heat_cycles** - Female dog heat cycle logging
- **matings** - Mating records for upcoming whelping predictions
- **kennel_profile** - Single-row kennel branding configuration

## UI Screens

1. **Dashboard** - Search bar, dog list with sale status badges, quick-add FAB, upcoming agenda (whelpings + heat cycles)
2. **Dog Detail** - Identity card, photo gallery, interactive pedigree canvas with PDF export/share, health/show records tabs
3. **Add/Edit Dog** - Create or edit dog profiles with photo upload, sale status, color, microchip, etc.
4. **Health Record** - Log vaccines, deworming, vet visits with next due date and notification scheduling
5. **Show Record** - Log event name, date, judge, placement, title awarded
6. **Litter List** - Browse all registered litters with details
7. **Litter Form** - 3-step wizard (parents -> dates -> puppy roster)
8. **Matchmaker** - Sire/dam selection with real-time COI calculation and hypothetical pedigree preview
9. **Heat Tracker** - Expansion cards for each female with logged heat cycles
10. **Analytics** - Kennel statistics overview (dog count, breed distribution, litter averages)
11. **Financials** - Revenue/expense list with net summary and add transaction
12. **Settings** - Kennel profile, backup/migration, appearance/theming, financials, about
13. **Kennel Profile** - 4-tab form (Identity, Breeding, Contact, Appearance) with logo upload
14. **Backup & Migration** - SQLite backup/restore and CSV export/import
15. **Appearance** - Dark/Light/System mode, accent color picker
16. **About** - Developer info, links, in-app changelog

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a detailed history of changes.

## Developer

- **NiiAbe** - [niiabe.github.io](https://niiabe.github.io)

## Repository

[github.com/niiabe/zooped-flowos](https://github.com/niiabe/zooped-flowos)

## License

Private project - All rights reserved.
