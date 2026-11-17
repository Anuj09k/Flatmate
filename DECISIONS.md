# Architectural & Product Decisions (`DECISIONS.md`)

This document records all `(suggested)` defaults adopted from the product specification as well as architectural clarifications approved before Phase 1.

## 1. Approved Architecture & Spec Clarifications
1. **Separate Admin Web Project**: The moderation admin panel is built as a standalone web application outside the Flutter mobile codebase, protected by server-side `users.role = 'admin'` RLS and RPC checks. A basic version launches in Phase 2 (manual verification review), expands in Phase 4 (reports and appeals), and completes in Phase 7 (flagged photos, suspensions, prompt catalog editor, config viewer).
2. **Store-Reported Pricing on Paywall**: The mobile paywall renders live prices and introductory offers reported by the store (`RevenueCat` offerings). Locally calculated base + 18% GST figures in `AppConfig` are retained strictly for unit tests and offline/fallback display.
3. **Mutual-Match Swipes & Full Deck Lock**: While a user's swipe deck is open, a right swipe on someone who has already liked them creates a match without consuming the weekly right-swipe quota. Once the weekly right-swipe quota is exhausted (Free: 5, Plus: 25), the swipe deck locks completely (both right and left swipes stop) until the Monday 00:00 IST reset. Matches, existing chats, and the Likes counter remain accessible.
4. **Server-Side Test Suite**: Every phase includes server-side SQL (`pgTAP`) / Edge Function tests alongside Dart tests to verify RLS policies, quota enforcement, strikes, verification locks, and boost stacking directly in Postgres.
5. **Prepaid Non-Renewing Passes for Transferable Pro Plans**: Pro 6-month and Yearly plans are sold as prepaid, non-renewing store passes so the server can move the remaining entitlement duration once to another verified, non-Pro user while revoking the sender's Pro access.
6. **Two-Stage Compatibility Pipeline & Pair Caching**: The compatibility engine filters candidates in Postgres by geographic location (PostGIS) and hard `Must have` rules first, computes weighted two-way scores (`sqrt(score_a_to_b * score_b_to_a)`) only for passing candidates, and caches scores per ordered user pair.
7. **Configurable Early-Chat Contact Lock**: Raw phone numbers, social handles, and off-platform links are blocked during the first `chat_early_message_contact_lock_count` (default `5`) messages of a match chat unless shared via the in-app **Share Contact** safety flow.

## 2. Adopted `(suggested)` Defaults from Sections 4–21
- **Auth Method (Sec 6)**: Phone number with 6-digit OTP is the primary sign-up method; email is optional.
- **Minimum Age (Sec 3, 18)**: `18` years old, checked against date of birth at sign-up and cross-checked against government ID during verification.
- **Profile Photo Rules (Sec 6, 18)**: Minimum `2`, maximum `6` photos. First photo cannot be a group photo; sunglasses cannot appear in all photos.
- **Lister Flat Photo Location Check (Sec 6)**: EXIF coordinates on uploaded flat photos are compared against the listing's locality coordinates. A distance mismatch above `max_photo_location_mismatch_km` (`5.0` km) flags the listing for manual admin review (`flagged_location_mismatch`).
- **Unverified User Limited Mode (Sec 7, 21)**: During the 15-day verification window, unverified users have status `limited`—they can complete their profile and browse in read-only mode, but cannot swipe or chat on the server.
- **Face Scan Directions (Sec 7, 18)**: `['straight', 'left', 'right', 'up']` with at least `2` clear captures required and max `3` failed attempts per 24 hours before a 24-hour cooldown and manual review option.
- **Golden Badge Tooltip (Sec 7)**: Golden badge tooltip explicitly states it represents a paid membership only, not higher trust.
- **Filters Access (Sec 8, 21)**: Free users have full access to Basic and Advanced lifestyle/home filters (including Women-only safety mode) with `Must have` and `Nice to have` toggles so the compatibility score is accurate for everyone. Only explicit Premium filters (`New here`, `Recently active`, `Verified 6+ months`, `Fast responders`, `Same college/company`, `Saved searches`) require Plus or Pro.
- **New Profile Lift & Boost Cap (Sec 9, 18)**: New profiles receive a `48`-hour visibility lift (`+5` ranking points). Active Profile Boosts add up to `+12` ranking points, strictly capped so a boosted profile never ranks above an organic match scoring `15` or more points higher.
- **Weekly Quota Reset Time (Sec 10, 18)**: Every Monday at `00:00` India Standard Time (`Asia/Kolkata`).
- **Superchat Note Length (Sec 10, 18)**: Up to `200` characters, scanned by the contact-detail blocker.
- **Prompt Length & Count (Sec 12, 18)**: Exactly `3` prompts per profile, up to `150` characters per answer. Extra prompt slots and voice prompts are deferred to v2 (Sec 21).
- **Boost Stacking Bonus (Sec 11, 18, 21)**: 1 boost = `24` hours; 2 stacked boosts = `60` hours (`48 + 12` bonus hours); 3 stacked boosts (Pro) = `84` hours (the `12`-hour bonus applies once). Unused weekly boosts and Superchats do not carry over.
- **Strike Escalation & Reset (Sec 13, 18)**: Strikes 1–3 block the message and warn the user; Strike 4 suspends for `3` days, Strike 5 for `7` days, and Strike 6+ for `30` days. Strikes reset after `90` clean days.
- **Working Title & Launch City (Sec 19, 21)**: Working title is `"Flatmate App"`, launching initially in Mumbai suburbs (Andheri, Bandra, Powai, Goregaon, Malad, Kurla, Thane).
