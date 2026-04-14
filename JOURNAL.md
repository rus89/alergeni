# Project Journal

## 2026-04-14: Project Retrospective — Full State Capture

### What is this app?

**Udahni** ("Breathe in") is a Flutter app that displays real-time pollen and allergen data
for Serbia, sourced from the Serbian government's open data API at `http://77.46.150.200`.
It tracks 26 allergens across 29 monitoring stations. The app is in **Closed Testing** on
Google Play and targeting production release.

- **Package name:** `com.serbiaOpenData.udahni`
- **Display name:** "Udahni" (Android), "Alergeni" (iOS) — naming inconsistency exists
- **Version:** 1.1.0+3 (tagged as `v1.1.0`)
- **Repo:** https://github.com/rus89/alergeni.git

### Architecture

MVVM with Provider. Three layers:
- `core/` — config, constants, errors (AppError sealed class), helpers, theme
- `data/` — models (7), services (PollenApiService), repositories (PollenRepository with caching)
- `presentation/` — viewmodels (3: Home, Map, PersonalAllergen), screens (5), widgets (11)

Data flow: REST API → PollenApiService (with retry/backoff) → PollenRepository (with in-memory
cache) → ViewModels (ChangeNotifier) → Screens/Widgets (context.watch)

No domain/use-case layer. ViewModels call repository directly.

### Key technical details

- **API is plain HTTP** — Android has a network_security_config exception for `77.46.150.200`
- **Two distinct API paths:** `/api/opendata/*` for most endpoints, `/api/site/{id}/` for
  weekly summaries (different base path, not under opendata)
- **Retry logic:** Exponential backoff, 300ms base, 4s cap, max 3 retries. Retries on 408,
  429, 5xx, SocketException, TimeoutException, ClientException
- **Batch concentration fetching:** Three-strategy fallback (`id__in=`, repeated `id=` params,
  then chunked individual fetches in groups of 6)
- **Persistence:** SharedPreferences for selected location ID and personal allergen IDs
- **Off-season:** October through January. Auto-detected, shows dialog
- **Historical data fallback:** If today has no data, tries 1 year ago, then 2 years ago
- **Geolocator** for nearest-station detection (GPS)
- **All UI text is in Serbian**

### Dependencies (runtime)

flutter_map, geolocator, http, latlong2, provider, shared_preferences — all standard, no
exotic deps.

### Development history

80 commits over ~10 weeks (Jan 26 – Apr 2, 2026), entirely by Milan.

**Phase 1 (Jan 26-27):** Foundation — models, repository, first widgets
**Phase 2 (Feb 2-4):** Core screens (Home, About, Map) + navigation
**Phase 3 (Feb 6):** UI polish — status cards, icons, theming
**Phase 4 (Feb 9-10):** Major MVVM refactor — extracted ApiService, ViewModels, ApiConfig
**Phase 5 (Feb 11):** Data enrichment — Site model, map legends, shared state widgets
**Phase 6 (Feb 12):** Feature sprint — GPS, persistence, responsive layout, release config (19 commits in one day!)
**Gap (Feb 13 – Mar 29):** No commits for 46 days
**Phase 7 (Mar 30):** Added CLAUDE.md engineering guidelines
**Phase 8 (Apr 1-2):** Production readiness with AI assistance (Claude Opus 4.6):
  - Typed error handling (AppError sealed class)
  - Personal allergen selection + highlighting
  - Smart first-run experience
  - Version bump to 1.1.0+3

### What was delivered in v1.1.0

Three features per the design spec at `docs/superpowers/specs/2026-04-02-production-readiness-design.md`:
1. Smart first-run experience — auto-location + contextual hints
2. Personal allergen profile — selection screen + highlighting in top allergens card
3. Typed error handling — AppError sealed class wired through all layers

All three were implemented and reviewed. ABOUTME headers added to all files.

### Known issues & technical debt

1. **Test coverage is very thin** — only 2 test files (AppError + PersonalAllergenViewModel).
   No tests for HomeViewModel (606 lines), PollenApiService (420 lines), MapViewModel,
   PollenRepository, any screen, or any widget. This conflicts with the TDD mandate in
   CLAUDE.md.
2. **Hardcoded version in AboutScreen** — shows "Verzija 1.0.0" while pubspec has 1.1.0+3.
3. **Potentially unused widgets** — PollenStatusCard, OffSeasonMessage, and AllergenCard may
   not be referenced by any current screen (holdovers from earlier UI iterations).
4. **MapViewModel sequential prefetching** — fetches site data for 29 locations one-by-one
   in a for-loop. Could be slow.
5. **HTTP-only API** — no HTTPS. The API server itself doesn't support TLS.
6. **Name inconsistency** — "Udahni" on Android, "Alergeni" on iOS.
7. **Play Store release checklist** has unchecked items — see PLAY_STORE_RELEASE_CHECKLIST.md.
8. **Stale branches** — `refactor/extract-level-helper` and `xenodochial-noyce` are fully
   merged, could be cleaned up.

### What was explicitly scoped out (from design spec)

- Push notifications
- Historical data / trend charts
- Onboarding tutorial screens
- Offline data caching
- Dark mode
- Localization beyond Serbian
- Home screen widgets

### File size watchlist

Largest files that may need attention:
- `home_view_model.dart` — 606 lines (complex, lots of state)
- `map_screen.dart` — 530 lines
- `pollen_api_service.dart` — 420 lines
- `about_screen.dart` — 420 lines
- `home_screen.dart` — 360 lines

### Tags

- `v1.0.0+1` — initial stable release (per-resource error tracking)
- `v1.0.0+2` — build number bump
- `v1.1.0` — production readiness release (points to commit 861aa85, version 1.1.0+3)
