# Udahni — Pollen & Allergen Tracker for Serbia

> Real-time pollen and allergen concentration data across Serbia, powered by the national environmental monitoring network.

![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart_3.10+-0175C2?logo=dart&logoColor=white)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS-lightgrey)
![Tests](https://img.shields.io/badge/tests-238_passing-brightgreen)

---

Track 26 allergens across 29 monitoring stations, see what's in the air near you, and follow only the allergens that matter to your health.

---

## Features

### Data & Coverage

- **26 allergens** — grasses, trees, weeds, and mold spores
- **29 monitoring stations** nationwide
- **Historical fallback** — if today's data is unavailable, falls back to the same date one or two years prior
- **Off-season detection** — October through January, the app detects the inactive season and informs the user automatically

### Five Screens

- **Početna (Home)** — Daily snapshot card, top allergens ranked by concentration, weekly trend summary, and location selector
- **Mapa (Map)** — Interactive map of all monitoring stations; tap any pin to inspect current concentrations
- **Podešavanja (Profile)** — Personal allergen selection; chosen allergens are highlighted throughout the app
- **Uvod (Onboarding)** — Guided first-run experience with location auto-detection
- **O aplikaciji (About)** — Data source attribution and app info

### Technical Highlights

- Nearest-station auto-detection via GPS
- Exponential backoff retry — 300 ms base, 4 s cap, max 3 retries, on network errors and 5xx responses
- Batch concentration fetching with a three-strategy fallback (`id__in=` → repeated `id=` params → chunked individual requests)
- In-memory repository cache — data is fetched once per session
- Personal allergen preferences persisted across sessions with `shared_preferences`

---

## Tech Stack

| Category | Technology |
|---|---|
| Framework | Flutter / Dart 3.10+ |
| State Management | Provider (`ChangeNotifier`) |
| Networking | `package:http` |
| Maps | `flutter_map` + `latlong2` |
| Location | `geolocator` |
| Persistence | `shared_preferences` |
| UI Language | Serbian |

---

## Data Sources

All data is fetched at runtime from the Serbian environmental monitoring API at `http://77.46.150.200`. The app bundles no pollen data.

| Endpoint | Contents |
|---|---|
| `/api/opendata/` | Allergen types, stations, pollen records, concentrations |
| `/api/site/{id}/` | Weekly summaries per station |

> **Note:** The server is HTTP only — there is no HTTPS support on the API host. Android has a
> `network_security_config` exception for this address.

> **Disclaimer:** This is an independent project. It is not affiliated with or endorsed by any Serbian government body.

---

## Getting Started

### Prerequisites

- Flutter SDK (Dart ≥ 3.10)
- Android: API level 21+
- iOS: deployment target 12.0+

### Setup

```bash
git clone https://github.com/rus89/alergeni.git
cd alergeni
flutter pub get
flutter run
```

No environment variables, API keys, or `.env` files needed.

### Testing

```bash
flutter test          # 238 tests
flutter analyze       # 0 issues
dart format .         # format all Dart files
```

---

## Architecture

MVVM with Provider. Three layers with no domain/use-case layer in between — ViewModels call the repository directly.

```
lib/
├── core/           # Config, constants, AppError (sealed), helpers, theme
├── data/           # Models (7), PollenApiService, PollenRepository (in-memory cache)
└── presentation/   # ViewModels (3), Screens (5), Widgets (11)
```

Data flow: `REST API → PollenApiService → PollenRepository → ViewModels → Screens`

---

Built with [Flutter](https://flutter.dev) and open data from the Serbian environmental monitoring network.
