# Changelog

All notable changes to ZooPed will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.4.0] - 2026-06-17

### Added

- **Unified FileStorageService** - Eliminates memory leaks by recursively wiping orphaned high-res images from device storage upon dog or gallery deletion.
- **Global Error Isolation** - Implemented robust `DatabaseException` map within `PedigreeRepositoryImpl` to insulate UI from Drift/SQLite constraint failures.

### Changed

- **CPU Stream Optimization** - Refactored `HeatTrackerTab` to use Riverpod `StreamProvider.family.autoDispose`, resolving severe SQLite Stream explosion and CPU bloat.
- **Parallel Asynchronous Rendering** - `DogDetailScreen` now loads Pedigree Trees and Photo Galleries in parallel using `Future.wait()`, unblocking the main thread.
- **UX Lockdown** - Enforced tap-only UX on complex screens (Matchmaker, Dog Detail) by explicitly setting `NeverScrollableScrollPhysics()`, eliminating swiping lag.

## [1.3.0] - 2026-06-17

### Added

- **Matchmaker COI Prediction** - Select a sire & dam to calculate inbreeding coefficient using concurrent 5-generation ancestor traversal.
- **SQL Search Indexes** - Added indexes on `call_name`, `registered_name`, `microchip_number` for instant search.
- **SQL Push-Down Heat Filter** - Replaced inefficient Dart-side filtering with `getDogsForDropdown('Female')` for 1000+ dog kennels.
- **Keep-Alive Caching** - Dashboard and kennel profile providers now survive back-navigation for instant re-render.
- **Core Library Desugaring** - Enabled `isCoreLibraryDesugaringEnabled` for Android SDK 33+ compatibility with `flutter_local_notifications`.

### Changed

- **Dog Query Optimization** - `getDogById()` now executes 2 DB queries (dog + immediate parents); `getDogByIdFlat()` returns a flat dog in 1 query; `getDogByIdWithPedigree()` builds the full 3-generation tree.
- **Architecture Simplification** - Removed 12 pass-through use case files from pedigree domain; all callers use `pedigreeRepositoryProvider` directly.
- **Edit/Add Dog Screens** - Parent fetch eliminated in `_saveDog()`; uses `toCompanion(overrideSireId:, overrideDamId:)` to pass IDs directly.
- **Settings Screen Reorder** - New order: Kennel Profile, Backup & Migration, Appearance, About.

### Fixed

- **Zero-Warning Codebase** - Resolved 31 analyzer issues across 8 files (ambiguous imports, API mismatches, unused fields, dead code, bracket errors).
- **Database Migration v9** - Removed invalid `idx_transactions_dog_id` index on a non-existent column, fixing startup crash on existing databases.
- **Matchmaker Bracket Structure** - Restored broken widget tree causing cascading parse errors in matchmaker screen.

## [1.2.0] - 2026-06-17

### Added

- **Litters & Offspring** - New 4th tab on Dog Profile displaying linked litters and directly-sired offspring.
- **Dashboard Filtering** - Added comprehensive bottom sheet filters allowing A-Z, Age, Recent sorting, and Male/Female filtering.
- **Dynamic Theming** - Replaced legacy static colors with dynamic appearance settings. Users can toggle Dark/Light mode and select from 6 premium color accents.
- **Official Pedigree PDF** - Massively upgraded the "Share PDF" layout to an official A4 Landscape certificate containing the 3-generation visual pedigree tree and preloaded ancestral photos.

### Fixed
- **Architectural Polish** - Achieved 0 compiler warnings, permanently resolving missing BuildContext checks across deep async gaps and deprecation alerts inside forms.

## [1.1.1] - 2026-06-17

### Added

- **Kennel Contacts** - Added specific Phone, WhatsApp, and Email fields to Kennel Profile
- **Database Schema v6** - Migrated local database to support expanded profile fields

### Fixed

- **Dashboard Refresh** - Fixed an issue where the dog list wouldn't update immediately after a dog was deleted
- **Database Size Refresh** - Added SQLite VACUUM optimization to accurately calculate and compress the database size when refreshing backups

## [1.1.0] - 2026-06-17

### Added

- **Edit Dog Screen** - Edit existing dog profiles via `/dog/:id/edit` route
- **Litter Browse Screen** - List all registered litters with sire/dam names and puppy counts
- **Dog Photo Support** - Add photos to dog profiles; displayed on detail screen
- **CSV Import Dedup** - Import validation skips duplicates by registered name and microchip

### Fixed

- **Pedigree Tree Performance** - Replaced N+1 recursive queries with batched ancestor loading
- **Updated about screen logo and layout**

## [1.0.1] - 2026-06-17

### Added

- Added Great Grandparents to the pedigree tree (5-generation display)

### Fixed

- Fixed pedigree tree connection wires rendering
- Fixed duplicate dog database insertion error when adding new dogs
- Patched a memory leak in the pedigree canvas
- Resolved duplicate search suggestion entries

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
