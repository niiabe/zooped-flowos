---
name: global-rules
description: Use ALWAYS for all projects. Global rules for data preservation, version control, and release builds that must be followed in every session.
---

# Global Development Rules

These rules apply to ALL projects regardless of language or framework.

## 1. Data Preservation

Updates must never wipe out existing data. Always ensure database schema migrations are properly handled to prevent data loss.

- When modifying database tables, write proper migration scripts (up and down)
- Test that existing data survives schema changes
- Never drop columns or tables without a migration path
- Use transactions for multi-step migrations

## 2. Version Control Streamlining

Always ensure version numbers are updated in the project's primary configuration file and streamlined across the app.

- Update version in `pubspec.yaml`, `build.gradle.kts`, `package.json`, or equivalent
- Do NOT hardcode version numbers in the UI - read them from config at runtime
- Keep `CHANGELOG.md` updated before every release with all changes
- Version format: `MAJOR.MINOR.PATCH+BUILD` (e.g. `1.9.5+21`)

## 3. Local Release Builds

When doing a release, always build the production release artifact locally using the framework's native build tools first.

- **Flutter**: `flutter build apk --release`
- **Android**: `./gradlew assembleRelease`
- **npm/Node**: `npm run build`
- Then create the GitHub release and upload the local artifact manually
- Do NOT rely on GitHub Actions for the final release artifact due to potential keystore or environment incompatibilities
