# Changelog

All notable changes to ZooPed will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.7.0+14] - 2026-06-21

### Changed

- **Architectural Scaling & Optimization Update**
- **Memory Optimization:** Converted `FutureProvider` database streams to `autoDispose` to instantly release memory resources and eliminate background zombie SQLite connections. Fixed image decoding bloat by explicitly clamping cache sizes on large gallery profiles.
- **Isolate Offloading:** Migrated the heavy A4 Pedigree PDF Generator and compression logic entirely off the UI thread onto a background `compute()` isolate, guaranteeing 120Hz scrolling and zero application freezing during large exports.
- **Data Security Integration:** Hardened the SQLite persistence layer with comprehensive input boundary sanitization (using deep `.trim()`) to prevent trailing whitespace injections and database corruption.
- **N+1 Database Query Fix:** Re-engineered the lineage tree traversal engine away from an $O(N)$ recursive loop to a batched, Depth-based $O(Depth)$ query utilizing SQLite `isIn()` statements. Database locks during matchmaker lookups are entirely eradicated.
- **File Storage Permanence:** Fixed a critical flaw in `image_picker` logic that allowed the OS cache manager to delete user profile pictures. Migrated all dog and kennel images automatically into a persistent, un-deletable app sandbox.
- **UX Search Debouncing:** Installed an asynchronous backend `Future.delayed` cancellation layer on the Dashboard Search Bar to prevent the `dogsProvider` from launching massive concurrent SQLite queries during rapid typing.

## [1.6.0+13] - 2026-06-21

### Added
- **Custom Kennel Themes & Border Designs:** Personalize your app experience! You can now select a custom Brand Color and choose from 5 premium border styles (Classic, Modern, Elegant, Regal, Bold) from your Kennel Profile. These elements elegantly theme the app and change the base color and styling of all exported PDF Pedigree Certificates to match your kennel's unique identity.
- **Categorized Kennel Setup:** The Kennel Profile screen has been beautifully redesigned and categorized into tabs (Identity, Breeding, Contact, Appearance) to make setting up your kennel easier and more intuitive.
- **Hypothetical Matchmaker Certificates:** You can now generate, preview, and share official Pedigree Certificates for hypothetical puppies directly from the Matchmaker screen, complete with projected COI.
- **Appraisal Score Badges:** Dogs with recorded appraisal scores now feature beautiful, animated medal badges (Gold, Silver, Bronze, Verified) on their detail pages and dashboard cards, adding a premium feel to your champions.
- **Premium UI Animations:** We've added buttery-smooth staggered animations, satisfying scale effects, and completely redesigned "Empty States" across the Matchmaker, Dashboard, and Analytics screens to make the app feel alive and incredibly premium.

## [1.5.0+12] - 2026-06-21

### Added
- **Predictive Breed Input:** You can now configure your primary breeding focus under the **Kennel Profile** (e.g. "French Bulldog, Poodle"). When adding or editing a dog, the Breed field will now dynamically predict and auto-complete breeds from your Kennel Profile as you type, significantly speeding up data entry and preventing typos!

### Changed
- **Dynamic Versioning:** The About Screen now reads the version number dynamically from the core app configuration, ensuring the version displayed matches the actual build exactly.
- **Social Pedigree Sharing:** The "Social" share button now generates and shares a high-quality rasterized image version of the official PDF Certificate, rather than capturing a raw screenshot of the Pedigree Canvas.
- **Breed Information Pervasiveness:** Breed information is now visible throughout the app, including the Dashboard (Dog Cards), Dog Details, Pedigree Certificate, and Kennel Analytics.
- **Social Share Appearance:** Fixed the transparent background issue on the generated social media share image, ensuring it now renders with a clean white background.
- **Certificate Watermark:** Cleaned up the PDF Certificate watermark so that it now strictly displays only the beautiful Zooped logo, removing the extra scattered background icons.

## [1.4.1+11] - 2026-06-20

### Fixed
- **Heat Tracker UI Restored:** Fixed a major bug where navigating to the Heat Tracker tab incorrectly displayed the Simulate Breeding (Matchmaker) screen instead. The Heat Tracker is now fully accessible and fully functional.
- **Instant UI Refresh:** Fixed a state management bug where adding a new litter wouldn't immediately show up on the Litters screen until the user manually refreshed or re-entered the page. The app now instantly auto-invalidates the provider the millisecond the "Register Litter" screen successfully closes.
- **Live Input Validation:** Added real-time input validation across the entire app (Dog Forms, Litter Forms, Kennel Profile, Health & Show Records). Fields like Microchip Number now instantly warn you while you are typing instead of waiting until you click Save.

## [1.4.0+10] - 2026-06-20

### Fixed
- **Circular Pedigree Prevention:** Fixed a major bug where a dog could be assigned as its own parent. The Edit Dog screen now performs a full recursive SQL database scan to actively hide any children, grandchildren, or deep descendants from the sire/dam selection lists, completely preventing infinite pedigree loops. If a dog's pedigree is already corrupted, opening the Edit screen will automatically detect and repair the broken lineage by clearing the invalid parent.
- **Health Reminder Crash:** Fixed a crash on Android 13+ devices when adding a Health Record. Added strict `SCHEDULE_EXACT_ALARM` permissions to the manifest and built a fail-safe that guarantees the record always saves even if the device's custom OS actively blocks calendar reminders.

## [1.4.0+9] - 2026-06-20

### Fixed
- **Pedigree Canvas Fix:** Fixed a critical bug where adding a missing parent (or grandparent) via the pedigree canvas would accidentally delete the other parent.
- **Pedigree Canvas Defaults:** Dogs added directly from the pedigree canvas now automatically default to a "Not Owned" sale status to prevent cluttering the main kennel dashboard.

## [1.4.0+8] - 2026-06-20

### Added
- Added "Not Owned" option to sale status dropdowns in add and edit dog screens to properly categorize non-owned parent dogs in pedigrees.
- **Pedigree PDF Watermark:** Added a large, elegant ZooPed logo and paw prints as a background watermark on exported Pedigree Certificates.
- **Dog Profile Banner Image:** The dog's uploaded profile picture is now elegantly displayed as a circular avatar directly in the top banner of the Dog Detail screen.

### Changed
- Filtered dogs marked as "Not Owned" from appearing in the main kennel dashboard list and search results, keeping the dashboard focused only on owned dogs.
- **Input Validation:** Enforced strict numeric input formatting on Microchip, Phone, and Financial transaction fields to physically block clipboard copy-paste vulnerabilities.


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
