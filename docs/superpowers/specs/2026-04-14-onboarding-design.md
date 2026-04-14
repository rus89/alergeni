# Onboarding Experience — Design Spec

**Date:** 2026-04-14  
**Status:** Approved  
**Scope:** User onboarding flow, in-screen contextual hints, profile+settings screen

---

## Overview

The feature introduces a polished onboarding experience to replace the existing `FirstRunHint` widget system, which is removed entirely. Three new building blocks are added to the existing MVVM+Provider architecture:

1. **`OnboardingScreen`** — full-screen intro cards shown on first launch
2. **`ProfileSettingsScreen`** — unified profile + settings destination, accessible from the app bar
3. **`HintCard`** widget + persistent info icons — contextual hints shown on first visit to each screen

No new pub dependencies. No changes to the existing three ViewModels.

---

## Onboarding Screen (Intro Cards)

`OnboardingScreen` is a standalone screen with no ViewModel. It uses a `PageView` with a `PageController` and renders 4 `OnboardingCard` widgets.

### Cards

| # | Title | Content |
|---|-------|---------|
| 1 | Welcome | App name + one-line value proposition: "Prati polene i alergene u Srbiji" |
| 2 | Početna | Explains the daily pollen snapshot, location selector, and severity levels |
| 3 | Mapa | Explains the Serbia map and how to read station markers |
| 4 | Moji alergeni | Explains personal allergen profile and highlighted tracking |

Each `OnboardingCard` contains: a large icon/illustration, a bold title, and a short subtitle (2–3 lines max). Cards do not have their own action buttons.

### Navigation Controls

Navigation controls live at the bottom of the screen, outside the cards:

- **Left:** "Preskoči" text button (skip) — visible on all pages
- **Center:** Dot page indicator
- **Right:** "Dalje" button (next) — becomes "Počni" on the last card

Both Skip and "Počni" call the same method: `OnboardingService.markOnboardingComplete()`, then `Navigator.pushReplacement` to `MainScreen`.

The screen uses existing `AppTheme` colours and typography throughout.

---

## Profile + Settings Screen

A gear icon (`Icons.settings_outlined`) is added to the `AppBar` on `MainScreen`, visible across all three tabs. Tapping it pushes `ProfileSettingsScreen` as a full-screen modal route.

### Structure

**Section: "Moji alergeni"**  
The existing allergen selection UI from `PersonalAllergenScreen`, reused as a child widget. No logic changes — just relocated. The existing entry point from the home screen is updated to point here instead.

**Section: "Podešavanja"**  
A `ListTile` with label "Ponovi uvod". On tap: calls `OnboardingService.resetOnboarding()`, then navigates to `OnboardingScreen` replacing the current route (so back doesn't return to settings mid-flow). Additional future settings drop in below as new `ListTile`s or sections.

The bottom nav (Home, Map, About) is unchanged.

---

## In-Screen HintCard & Info Icons

### HintCard Widget

A dismissible card anchored to the bottom of the screen (above the nav bar). Styled with the app's surface colour and subtle elevation. Shows a short Serbian tip (1–2 lines) and an "×" dismiss button.

**Props:** `String message`, `VoidCallback onDismiss`

**Trigger logic:** Each screen checks `OnboardingService.hasVisitedScreen(key)` in `initState` (via post-frame callback). If `false`, the `HintCard` is shown. On dismiss, `OnboardingService.markScreenVisited(key)` is called — the card never reappears.

**Screen keys and messages:**

| Screen | Key | Message |
|--------|-----|---------|
| HomeScreen | `'home'` | Tip about reading severity levels and selecting a location |
| MapScreen | `'map'` | Tip about tapping station markers for details |
| ProfileSettingsScreen | `'allergens'` | Tip about setting up personal allergen profile |

### Info Icons

Permanent `IconButton`s with `Icons.info_outline` placed inline next to complex UI elements. Tapping opens a `showDialog` with a title and explanation. They never disappear.

**Candidates:**

| Location | Explains |
|----------|---------|
| Severity colour legend (HomeScreen) | What each colour level means |
| Station selector (MapScreen) | How monitoring stations work |
| Allergen list header (ProfileSettingsScreen) | How personal allergen highlighting works |

---

## OnboardingService & Persistence

`OnboardingService` lives in `core/services/`. It wraps `SharedPreferences` and owns all onboarding-related persistence. No business logic — reads and writes only.

### SharedPreferences Keys

| Key | Type | Purpose |
|-----|------|---------|
| `onboarding_complete` | `bool` | Whether intro cards have been seen/skipped |
| `visited_screens` | `List<String>` | Which screens have had their HintCard dismissed |

### API

```dart
Future<bool> isOnboardingComplete()
Future<void> markOnboardingComplete()
Future<void> resetOnboarding()
Future<bool> hasVisitedScreen(String key)
Future<void> markScreenVisited(String key)
```

### App Startup

`main.dart` reads `isOnboardingComplete()` before running the app and sets the initial route to either `OnboardingScreen` or `MainScreen`. The existing `FirstRunHint` check in `HomeViewModel` is removed.

---

## Removals

- `FirstRunHint` widget — deleted entirely
- `FirstRunHint` usage in `HomeScreen` — removed
- Any `FirstRunHint`-related SharedPreferences keys in `HomeViewModel` — removed

---

## Testing

Tests are written before implementation (TDD). No integration tests — feature is UI-only with no network calls.

### `OnboardingService` unit tests
`test/core/services/onboarding_service_test.dart`

- Returns `false` for `isOnboardingComplete()` on fresh state
- Returns `true` after `markOnboardingComplete()`
- Resets correctly after `resetOnboarding()`
- `hasVisitedScreen()` returns `false` for unvisited, `true` after `markScreenVisited()`

### `OnboardingScreen` widget tests
`test/presentation/screens/onboarding_screen_test.dart`

- Renders first card on load
- "Dalje" advances to next page
- "Preskoči" calls `markOnboardingComplete()` and navigates away
- Last card shows "Počni" instead of "Dalje"
- "Počni" calls `markOnboardingComplete()` and navigates away

### `HintCard` widget tests
`test/presentation/widgets/hint_card_test.dart`

- Renders message text
- Tapping "×" calls `onDismiss`

### `ProfileSettingsScreen` widget tests
`test/presentation/screens/profile_settings_screen_test.dart`

- Renders allergen section and settings section
- "Ponovi uvod" tile calls `resetOnboarding()`
