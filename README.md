<p align="center">
  <img src="assets/images/AppBar.png" alt="ZooPed Logo" width="200"/>
</p>

# ZooPed - Dog Pedigree Tracker

A Flutter Android application for tracking dog pedigrees, designed for professional breeders and kennel clubs.

**Package:** `com.zooped.niiabe` | **Version:** 1.0.0 | **License:** Private

## Platform

- **Android Only** - Built exclusively for Android devices
- **Responsive Design** - Adapts seamlessly to phones and tablets of all sizes

## Features

- **Dog Identity Ledger** - Register and manage dogs with call names, registered names, microchip numbers, breed, color, and more
- **Interactive 3-Generation Pedigree Tree** - Zoomable/pannable InteractiveViewer canvas displaying sire/dam lineage with tap-to-navigate to ancestors
- **5-Generation PDF Export** - Generate professional A4 landscape pedigree certificates for printing or sharing
- **Litter Tracking** - Record matings, whelping dates, and auto-create puppy profiles with inherited parentage
- **Custom Kennel Branding** - Upload kennel logo and configure breeder profile (logo-driven theme)
- **CSV Backup & Import** - Export and import all dog/litter data as CSV files from the app documents directory
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
│   ├── database/       # Drift database definition
│   ├── router/         # go_router configuration
│   ├── services/       # CertificateService, CsvService
│   ├── theme/          # App theme (Green + Charcoal)
│   └── utils/          # Responsive utility
└── features/
    ├── pedigree/
    │   ├── domain/     # Entities, Repositories (abstract), Use Cases
    │   ├── data/       # Drift models, Repository implementations
    │   └── presentation/ # Screens, Widgets, Providers
    └── settings/
        ├── domain/     # KennelProfile entity, Settings Repository
        ├── data/       # Repository implementation
        └── presentation/ # Settings screen, Providers
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

- **dogs** - Core dog records with self-referencing sire/dam foreign keys
- **litters** - Breeding events linking sire/dam with whelping outcomes
- **kennel_profile** - Single-row kennel branding configuration

## UI Screens

1. **Dashboard** - Search bar, dog list, quick-add FAB
2. **Dog Detail** - Identity card + interactive 3-gen pedigree canvas with PDF export/share
3. **Litter Form** - 3-step wizard (parents -> dates -> puppy roster)
4. **Settings** - Kennel profile, logo upload, CSV backup/import
5. **About** - Developer info, links, in-app changelog

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a detailed history of changes.

## Developer

- **NiiAbe** - [niiabe.github.io](https://niiabe.github.io)

## Repository

[github.com/niiabe/zooped-flowos](https://github.com/niiabe/zooped-flowos)

## License

Private project - All rights reserved.
