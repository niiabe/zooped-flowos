# Changelog

All notable changes to ZooPed will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-06-14

### Added

- **Dog Identity Management** - Register dogs with call name, registered name, microchip, breed, color, sex, height, weight, date of birth, and notes
- **Interactive 3-Generation Pedigree Tree** - Zoomable/pannable InteractiveViewer canvas displaying sire/dam lineage with tap-to-navigate to ancestors
- **5-Generation PDF Certificate Generation** - Professional A4 landscape pedigree certificates with customizable kennel branding
- **PDF Sharing** - Share generated pedigree certificates via device sharing
- **Litter Tracking** - 3-step wizard: parent selection, whelping dates, and puppy roster with auto-created profiles
- **Puppy Auto-Create** - Puppy entries automatically saved as Dog records with litter and parent references
- **Custom Kennel Branding** - Upload kennel logo, configure breeder name and contact info
- **Logo-Driven Theme** - App colors derived from ZooPed logo (Green #3CB91A primary, Dark Charcoal #3D3D3D secondary)
- **CSV Export** - Export all dog and litter data as CSV files
- **CSV Import** - Import data from CSV files stored in the app documents directory
- **Search** - Search dogs by name, registered name, or microchip number
- **Responsive Design** - Adapts to phones and tablets with breakpoint-based layouts
- **About Screen** - Developer info, website, repository link, and in-app changelog
- **Offline-First Storage** - All data stored locally using SQLite via Drift
- **Splash Screen** - Custom splash screen with ZooPed branding
- **App Icon** - Custom launcher icon with adaptive icon support

### Architecture

- Clean Architecture: Domain, Data, Presentation layers
- Riverpod state management
- go_router navigation
- Drift database with self-referencing foreign key schema
- Shared providers for cross-screen state (sires, dams, kennel profile)
- Certificate service for PDF generation and printing
- CSV service for backup and import

### Technical

- Package: `com.zooped.niiabe`
- Android-only (non-Android platform folders removed)
- compileSdk: flutter.compileSdkVersion
- Min SDK: Flutter default
- Kotlin MainActivity
