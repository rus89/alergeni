# Production Readiness Update — Design Spec

**Date:** 2026-04-02
**Goal:** Improve app quality and completeness to move from Google Play Closed Testing to Production.

## Context

Udahni is a Flutter app that shows real-time pollen/allergen data for Serbia. It currently has three screens (Home, Map, About), pulls data from Serbia's open data API, uses Provider + MVVM, and targets Android. The app is in Closed Testing on Google Play and needs polish to be production-ready.

## Scope

Three focused improvements:

1. Smart first-run experience
2. Personal allergen profile (highlight mode)
3. Better error handling (network + API errors)

---

## 1. Smart First-Run Experience

### What

On first launch, the app automatically detects the user's location and selects the nearest monitoring station, so they land on a populated home screen without manual steps. Contextual hints orient first-time users to key UI elements.

### Behavior

- **First launch only:** Check if this is the first app launch via a SharedPreferences flag (`first_launch_completed`).
- **Auto-location:** Trigger the existing geolocation logic (same as the "My Location" button) automatically. If permission is granted and a nearest station is found, select it and load data.
- **Permission denied / unavailable:** Fall back to current behavior — no station selected, user picks from the dropdown. No error shown for this case; it's a graceful degradation.
- **Contextual hints:** Show small, dismissable tooltip-style overlays on first launch:
  - Location selector: "Promenite stanicu u bilo kom trenutku" (Change your monitoring station anytime)
  - Weekly summary card: "Ukupni nivo polena za vašu oblast ove nedelje" (Your area's overall pollen risk this week)
  - Top allergens card: "Vaši najzastupljeniji alergeni rangirani po koncentraciji" (Your top allergens ranked by concentration)
- **Dismissal:** Each hint is dismissed by tapping it. Set `first_launch_completed = true` as soon as the first-run flow starts (after location detection), so hints are a one-time best-effort — if the user navigates away before dismissing them all, they don't reappear.
- **Off-season:** If it's the first launch during off-season (Oct-Jan), the smart location still runs, but the off-season dialog takes priority. Hints still show on the home screen behind/after the dialog is dismissed.

### Implementation notes

- Reuse existing `_selectMyLocation()` logic from `HomeViewModel` / `LocationSelectorCard`.
- Hints can be simple `Tooltip` or custom overlay widgets positioned relative to their target cards.
- SharedPreferences is already a project dependency.

---

## 2. Personal Allergen Profile

### What

Users can mark which allergens personally affect them. Their allergens are visually highlighted in the Top Allergens card on the home screen.

### Allergen Selection Screen

- Accessible from the home screen (e.g., a small icon button in the app bar or on the Top Allergens card header).
- Lists all 26 allergens grouped by type (Trees, Grasses, Weeds) with section headers.
- Each allergen shows: Serbian name, Latin name, allergenicity potential chip.
- Each allergen has a toggle (switch or checkbox) to mark it as personal.
- Selections are persisted immediately to SharedPreferences as a list of allergen IDs.
- No "save" button needed — selections auto-save.

### Highlight Behavior

- In the **Top Allergens card** on the home screen, any allergen that matches the user's personal list gets a visual highlight.
- Highlight style: a small icon (e.g., a person icon or filled circle) and/or a subtle background tint or left border accent on that allergen's row.
- The ranking, data, and layout remain unchanged — highlights are purely additive.
- If no personal allergens are in the current top 5, the card looks exactly as it does now.
- If the user hasn't set any personal allergens, no highlights appear anywhere.

### Relationship to About screen

- The About screen's allergen table remains as-is (read-only reference).
- The new selection screen serves a different purpose (personal selection) and is a separate screen/sheet.

### Data storage

- SharedPreferences key: `personal_allergen_ids` storing a JSON-encoded list of integer allergen IDs.
- Loaded at app startup and held in memory (e.g., in HomeViewModel or a dedicated lightweight provider).

---

## 3. Better Error Handling (Network + API Errors)

### What

Replace generic error messages with informative, user-friendly error states that distinguish between network issues and API failures.

### Error Classification

Introduce a typed error representation (sealed class or enum) with these variants:

| Variant | Trigger | User Message | Icon |
|---------|---------|-------------|------|
| `noInternet` | `SocketException`, connection timeout | "Nema internet konekcije. Proverite vezu i pokušajte ponovo." (No internet connection. Check your connection and try again.) | `Icons.wifi_off` or `Icons.cloud_off` |
| `serverError` | HTTP 5xx responses | "Podaci trenutno nisu dostupni. Pokušajte ponovo malo kasnije." (Data currently unavailable. Try again shortly.) | `Icons.cloud_off` or `Icons.error_outline` |
| `notFound` | HTTP 404, empty responses where data is expected | "Podaci za ovu lokaciju nisu pronađeni." (Data for this location not found.) | `Icons.search_off` |
| `unexpectedError` | Anything else (parsing errors, unknown exceptions) | "Došlo je do greške. Pokušajte ponovo." (An error occurred. Try again.) | `Icons.error_outline` |

### Architecture Changes

- **Service layer (`PollenApiService`):** Catch specific exception types and throw/return typed errors instead of generic exceptions.
- **Repository layer (`PollenRepository`):** Propagate typed errors upward.
- **ViewModel layer:** Store the typed error (not just a string message) in state. Expose it to the UI.
- **UI layer (`ErrorState` widget):** Accept the typed error and render the appropriate icon, message, and a retry button. The retry button calls the relevant reload method on the ViewModel.

### Scope

- Applies to both Home and Map screens.
- Each screen/data-loading operation tracks its own error state (the app already moved to per-resource error tracking in a recent commit).
- The retry button should be prominent and clear.

### What this does NOT include

- Offline caching / showing stale data when offline. This is a potential future improvement but out of scope.
- Connectivity monitoring (listening for network state changes). The user manually retries.

---

## What's NOT in Scope

- Push notifications
- Historical data / trend charts
- Onboarding tutorial screens
- Offline data caching
- Dark mode
- Localization beyond Serbian
- Home screen widgets

---

## Success Criteria

1. A first-time user with location services enabled lands on a populated home screen without any manual interaction.
2. A user can mark their personal allergens and see them highlighted in the Top Allergens card.
3. When offline, the app shows a clear "no internet" message with a retry button instead of a generic error.
4. When the API returns an error, the app shows an appropriate message distinguishing it from a network problem.
5. All existing functionality continues to work unchanged.
