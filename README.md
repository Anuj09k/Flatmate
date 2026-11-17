# Flatmate App

A Flutter app for finding compatible flatmates in India. The current build contains the Phase 1 onboarding foundation and a warm, profile-led interface.

## Current features

- Seeker and lister onboarding flows
- Mock phone OTP signup and an 18+ age gate
- Profile setup with photo and prompt validation
- Contact-detail checks for bios and prompt answers
- Lister listing photo checks, including duplicate and EXIF location checks
- Shared product limits in `AppConfig`
- Supabase Phase 1 schema and SQL test files

## Run locally

```sh
flutter pub get
flutter run
```

The mock OTP is `123456`. Authentication, profiles, and listings currently use in-memory repositories; the Supabase client and production identity-verification providers are not wired into the app yet.

## Test

```sh
flutter test test/phase1_foundation_test.dart
```

## Supabase files

- Migration: `supabase/migrations/20261112000001_phase1_foundation.sql`
- SQL checks: `supabase/tests/phase1_foundation_test.sql`
- Sample seed data: `supabase/seed.sql`

Apply and test the SQL files with the Supabase CLI against a local development project before using them in a hosted environment.
