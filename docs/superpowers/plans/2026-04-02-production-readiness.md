# Production Readiness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Improve Udahni app quality for Google Play production release with smart first-run experience, personal allergen profiles, and typed error handling.

**Architecture:** Three independent features layered onto the existing Provider + MVVM architecture. A new `AppError` sealed class replaces raw string errors throughout the service → repository → viewmodel → widget chain. A `PersonalAllergenProvider` manages allergen selection state. First-run logic lives in `HomeScreen`'s `initState` with SharedPreferences flags.

**Tech Stack:** Flutter, Provider, SharedPreferences, Geolocator (existing deps — no new dependencies)

---

## File Map

### New Files

| File | Responsibility |
|------|----------------|
| `lib/core/errors/app_error.dart` | Sealed class defining typed error variants |
| `lib/presentation/viewmodels/personal_allergen_view_model.dart` | Manages personal allergen selection state + persistence |
| `lib/presentation/screens/personal_allergen_screen.dart` | Screen for selecting personal allergens |
| `lib/presentation/widgets/first_run_hint.dart` | Dismissable tooltip overlay widget |
| `test/core/errors/app_error_test.dart` | Unit tests for error classification |
| `test/presentation/viewmodels/personal_allergen_view_model_test.dart` | Unit tests for allergen profile logic |

### Modified Files

| File | What Changes |
|------|-------------|
| `lib/data/services/pollen_api_service.dart` | Throw `AppError` instead of generic `Exception` |
| `lib/data/repositories/pollen_repository.dart` | Propagate `AppError` (no catch changes needed) |
| `lib/presentation/viewmodels/home_view_model.dart` | Store `AppError?` instead of `String?` for errors; expose personal allergen IDs |
| `lib/presentation/viewmodels/map_view_model.dart` | Store `AppError?` instead of `String?` for error |
| `lib/presentation/widgets/error_state.dart` | Accept `AppError` and render icon + message per variant |
| `lib/presentation/widgets/top_allergens_card.dart` | Add `isPersonal` flag to `TopAllergenItem`; highlight row |
| `lib/presentation/screens/home_screen.dart` | First-run auto-location + hints; personal allergen button; pass `AppError` to `ErrorState` |
| `lib/presentation/screens/map_screen.dart` | Pass `AppError` to `ErrorState` |
| `lib/main.dart` | Register `PersonalAllergenViewModel` in `MultiProvider` |

---

## Task 1: Create `AppError` Sealed Class

**Files:**
- Create: `lib/core/errors/app_error.dart`
- Create: `test/core/errors/app_error_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/core/errors/app_error_test.dart`:

```dart
// ABOUTME: Tests for typed error classification used across the app.
// ABOUTME: Verifies factory correctly maps exceptions to error variants.

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:udahni/core/errors/app_error.dart';

void main() {
  group('AppError.fromException', () {
    test('classifies SocketException as noInternet', () {
      final error = AppError.fromException(
        const SocketException('No route to host'),
      );
      expect(error, isA<NoInternetError>());
      expect(error.userMessage, contains('internet'));
    });

    test('classifies TimeoutException as noInternet', () {
      final error = AppError.fromException(
        TimeoutException('Request timed out'),
      );
      expect(error, isA<NoInternetError>());
    });

    test('classifies generic Exception as unexpected', () {
      final error = AppError.fromException(Exception('something broke'));
      expect(error, isA<UnexpectedError>());
      expect(error.userMessage, contains('greške'));
    });
  });

  group('AppError.fromHttpStatus', () {
    test('classifies 500 as serverError', () {
      final error = AppError.fromHttpStatus(500);
      expect(error, isA<ServerError>());
      expect(error.userMessage, contains('dostupni'));
    });

    test('classifies 503 as serverError', () {
      final error = AppError.fromHttpStatus(503);
      expect(error, isA<ServerError>());
    });

    test('classifies 404 as notFound', () {
      final error = AppError.fromHttpStatus(404);
      expect(error, isA<NotFoundError>());
    });

    test('classifies 400 as unexpected', () {
      final error = AppError.fromHttpStatus(400);
      expect(error, isA<UnexpectedError>());
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/milanrusimov/Documents/Projects/Flutter/serbia_open_data/alergeni && flutter test test/core/errors/app_error_test.dart`

Expected: Compilation error — `app_error.dart` does not exist yet.

- [ ] **Step 3: Write minimal implementation**

Create `lib/core/errors/app_error.dart`:

```dart
// ABOUTME: Typed error representations for user-facing error states.
// ABOUTME: Classifies network, server, and data errors with Serbian user messages.

import 'dart:async';
import 'dart:io';

sealed class AppError {
  const AppError();

  String get userMessage;
  String get iconName;

  factory AppError.fromException(Object exception) {
    if (exception is SocketException || exception is TimeoutException) {
      return const NoInternetError();
    }
    return UnexpectedError(debugMessage: exception.toString());
  }

  factory AppError.fromHttpStatus(int statusCode) {
    if (statusCode >= 500) {
      return const ServerError();
    }
    if (statusCode == 404) {
      return const NotFoundError();
    }
    return UnexpectedError(debugMessage: 'HTTP $statusCode');
  }
}

class NoInternetError extends AppError {
  const NoInternetError();

  @override
  String get userMessage =>
      'Nema internet konekcije. Proverite vezu i pokušajte ponovo.';

  @override
  String get iconName => 'wifi_off';
}

class ServerError extends AppError {
  const ServerError();

  @override
  String get userMessage =>
      'Podaci trenutno nisu dostupni. Pokušajte ponovo malo kasnije.';

  @override
  String get iconName => 'cloud_off';
}

class NotFoundError extends AppError {
  const NotFoundError();

  @override
  String get userMessage =>
      'Podaci za ovu lokaciju nisu pronađeni.';

  @override
  String get iconName => 'search_off';
}

class UnexpectedError extends AppError {
  final String? debugMessage;

  const UnexpectedError({this.debugMessage});

  @override
  String get userMessage =>
      'Došlo je do greške. Pokušajte ponovo.';

  @override
  String get iconName => 'error_outline';
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /Users/milanrusimov/Documents/Projects/Flutter/serbia_open_data/alergeni && flutter test test/core/errors/app_error_test.dart`

Expected: All 6 tests PASS.

- [ ] **Step 5: Commit**

```bash
cd /Users/milanrusimov/Documents/Projects/Flutter/serbia_open_data/alergeni
git add lib/core/errors/app_error.dart test/core/errors/app_error_test.dart
git commit -m "Add AppError sealed class for typed error handling"
```

---

## Task 2: Wire `AppError` Into the API Service

**Files:**
- Modify: `lib/data/services/pollen_api_service.dart`

- [ ] **Step 1: Update `_getWithRetry` to throw `AppError` on final failure**

In `lib/data/services/pollen_api_service.dart`, add the import at the top (after existing imports):

```dart
import 'package:udahni/core/errors/app_error.dart';
```

Replace the three `rethrow` statements in `_getWithRetry` (lines 52, 55, 58) with `AppError.fromException` throws. Replace the entire `_getWithRetry` method (lines 35-66) with:

```dart
  Future<http.Response> _getWithRetry(Uri uri) async {
    final maxRetries = ApiConfig.maxRetries;

    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final response = await _httpClient
            .get(uri)
            .timeout(ApiConfig.requestTimeout);

        if (_shouldRetryStatusCode(response.statusCode) &&
            attempt < maxRetries) {
          await Future.delayed(_retryDelay(attempt));
          continue;
        }

        return response;
      } on TimeoutException {
        if (attempt >= maxRetries) throw AppError.fromException(TimeoutException('Request to $uri timed out'));
        await Future.delayed(_retryDelay(attempt));
      } on SocketException catch (e) {
        if (attempt >= maxRetries) throw AppError.fromException(e);
        await Future.delayed(_retryDelay(attempt));
      } on http.ClientException catch (e) {
        if (attempt >= maxRetries) throw AppError.fromException(e);
        await Future.delayed(_retryDelay(attempt));
      }
    }

    throw const UnexpectedError(
      debugMessage: 'Request failed after all retry attempts',
    );
  }
```

- [ ] **Step 2: Update `_handleResponse` to throw `AppError` on non-200 status**

Replace the `_handleResponse` method (lines 82-104) with:

```dart
  Future<R> _handleResponse<R>(
    http.Response response,
    R Function(dynamic json) parser,
  ) async {
    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      return parser(decoded);
    }

    throw AppError.fromHttpStatus(response.statusCode);
  }
```

- [ ] **Step 3: Run existing tests and verify app compiles**

Run: `cd /Users/milanrusimov/Documents/Projects/Flutter/serbia_open_data/alergeni && flutter test test/core/errors/app_error_test.dart`

Expected: All tests still PASS (this change doesn't break them).

Run: `cd /Users/milanrusimov/Documents/Projects/Flutter/serbia_open_data/alergeni && flutter analyze`

Expected: No errors (warnings are acceptable).

- [ ] **Step 4: Commit**

```bash
cd /Users/milanrusimov/Documents/Projects/Flutter/serbia_open_data/alergeni
git add lib/data/services/pollen_api_service.dart
git commit -m "Throw AppError from API service instead of generic Exception"
```

---

## Task 3: Update ViewModels to Store `AppError`

**Files:**
- Modify: `lib/presentation/viewmodels/home_view_model.dart`
- Modify: `lib/presentation/viewmodels/map_view_model.dart`

- [ ] **Step 1: Update `HomeViewModel` error fields from `String?` to `AppError?`**

In `lib/presentation/viewmodels/home_view_model.dart`, add the import:

```dart
import 'package:udahni/core/errors/app_error.dart';
```

Replace the four error field declarations (lines 23-26):

```dart
  String? _locationsError;
  String? _allergensError;
  String? _allergenTypesError;
  String? _pollenDataError;
```

with:

```dart
  AppError? _locationsError;
  AppError? _allergensError;
  AppError? _allergenTypesError;
  AppError? _pollenDataError;
```

Replace the `errorMessage` getter (lines 58-59):

```dart
  String? get errorMessage =>
      _locationsError ?? _allergensError ?? _allergenTypesError ?? _pollenDataError;
```

with:

```dart
  AppError? get error =>
      _locationsError ?? _allergensError ?? _allergenTypesError ?? _pollenDataError;
```

- [ ] **Step 2: Update each catch block in `HomeViewModel` to store `AppError`**

In `fetchLocations()` (line 127), replace:

```dart
      _locationsError = e.toString();
```

with:

```dart
      _locationsError = e is AppError ? e : AppError.fromException(e);
```

In `fetchAllergens()` (line 147), replace:

```dart
      _allergensError = e.toString();
```

with:

```dart
      _allergensError = e is AppError ? e : AppError.fromException(e);
```

In `fetchAllergenTypes()` (line 167), replace:

```dart
      _allergenTypesError = e.toString();
```

with:

```dart
      _allergenTypesError = e is AppError ? e : AppError.fromException(e);
```

Find the catch block in `fetchPollenConcentrationData()` that sets `_pollenDataError` and apply the same pattern:

```dart
      _pollenDataError = e is AppError ? e : AppError.fromException(e);
```

- [ ] **Step 3: Update `MapViewModel` the same way**

In `lib/presentation/viewmodels/map_view_model.dart`, add the import:

```dart
import 'package:udahni/core/errors/app_error.dart';
```

Replace the error field (line 14):

```dart
  String? _errorMessage;
```

with:

```dart
  AppError? _errorMessage;
```

Update the getter (line 19):

```dart
  String? get errorMessage => _errorMessage;
```

to:

```dart
  AppError? get error => _errorMessage;
```

In the `loadLocations()` catch block (line 39), replace:

```dart
      _errorMessage = e.toString();
```

with:

```dart
      _errorMessage = e is AppError ? e : AppError.fromException(e);
```

- [ ] **Step 4: Run analyze to check for compile errors**

Run: `cd /Users/milanrusimov/Documents/Projects/Flutter/serbia_open_data/alergeni && flutter analyze`

Expected: Errors in `home_screen.dart` and `map_screen.dart` because they still reference `errorMessage` — this is expected and will be fixed in the next task.

- [ ] **Step 5: Commit**

```bash
cd /Users/milanrusimov/Documents/Projects/Flutter/serbia_open_data/alergeni
git add lib/presentation/viewmodels/home_view_model.dart lib/presentation/viewmodels/map_view_model.dart
git commit -m "Store AppError instead of String in ViewModels"
```

---

## Task 4: Update `ErrorState` Widget and Screens

**Files:**
- Modify: `lib/presentation/widgets/error_state.dart`
- Modify: `lib/presentation/screens/home_screen.dart`
- Modify: `lib/presentation/screens/map_screen.dart`

- [ ] **Step 1: Update `ErrorState` to accept `AppError`**

Replace the entire contents of `lib/presentation/widgets/error_state.dart` with:

```dart
// ABOUTME: Displays user-friendly error messages with icons based on error type.
// ABOUTME: Renders different icons and messages for network, server, and unexpected errors.

import 'package:flutter/material.dart';
import 'package:udahni/core/errors/app_error.dart';

class ErrorState extends StatelessWidget {
  final AppError error;
  final VoidCallback? onRetry;

  const ErrorState({super.key, required this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_iconForError(error), color: _colorForError(error), size: 48),
            const SizedBox(height: 16),
            Text(
              error.userMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Pokušaj ponovo'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static IconData _iconForError(AppError error) {
    return switch (error) {
      NoInternetError() => Icons.wifi_off,
      ServerError() => Icons.cloud_off,
      NotFoundError() => Icons.search_off,
      UnexpectedError() => Icons.error_outline,
    };
  }

  static Color _colorForError(AppError error) {
    return switch (error) {
      NoInternetError() => Colors.blueGrey,
      ServerError() => Colors.orange,
      NotFoundError() => Colors.grey,
      UnexpectedError() => Colors.red,
    };
  }
}
```

- [ ] **Step 2: Update `HomeScreen` to use `AppError`**

In `lib/presentation/screens/home_screen.dart`, replace the import:

```dart
import 'package:udahni/presentation/widgets/error_state.dart';
```

(Keep this import — it stays the same.)

Add import:

```dart
import 'package:udahni/core/errors/app_error.dart';
```

In `_buildBody()`, replace the error check block (lines 76-81):

```dart
    if (viewModel.errorMessage != null) {
      return ErrorState(
        message: viewModel.errorMessage!,
        onRetry: viewModel.fetchLocations,
      );
    }
```

with:

```dart
    if (viewModel.error != null) {
      return ErrorState(
        error: viewModel.error!,
        onRetry: viewModel.loadInitialData,
      );
    }
```

- [ ] **Step 3: Update `MapScreen` to use `AppError`**

In `lib/presentation/screens/map_screen.dart`, replace the error block (lines 28-32):

```dart
          : mapViewModel.errorMessage != null
          ? ErrorState(
              message: mapViewModel.errorMessage!,
              onRetry: mapViewModel.refreshLocations,
            )
```

with:

```dart
          : mapViewModel.error != null
          ? ErrorState(
              error: mapViewModel.error!,
              onRetry: mapViewModel.refreshLocations,
            )
```

Add import at top:

```dart
import 'package:udahni/core/errors/app_error.dart';
```

- [ ] **Step 4: Run analyze and tests**

Run: `cd /Users/milanrusimov/Documents/Projects/Flutter/serbia_open_data/alergeni && flutter analyze && flutter test`

Expected: No errors, all tests pass.

- [ ] **Step 5: Commit**

```bash
cd /Users/milanrusimov/Documents/Projects/Flutter/serbia_open_data/alergeni
git add lib/presentation/widgets/error_state.dart lib/presentation/screens/home_screen.dart lib/presentation/screens/map_screen.dart
git commit -m "Wire AppError through to ErrorState widget in both screens"
```

---

## Task 5: Create `PersonalAllergenViewModel`

**Files:**
- Create: `lib/presentation/viewmodels/personal_allergen_view_model.dart`
- Create: `test/presentation/viewmodels/personal_allergen_view_model_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/presentation/viewmodels/personal_allergen_view_model_test.dart`:

```dart
// ABOUTME: Tests for personal allergen selection and persistence logic.
// ABOUTME: Verifies toggle, load, and query behavior of PersonalAllergenViewModel.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udahni/presentation/viewmodels/personal_allergen_view_model.dart';

void main() {
  group('PersonalAllergenViewModel', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('starts with empty selection', () async {
      final vm = PersonalAllergenViewModel();
      await vm.loadSelections();
      expect(vm.selectedAllergenIds, isEmpty);
    });

    test('toggling an ID adds it', () async {
      final vm = PersonalAllergenViewModel();
      await vm.loadSelections();
      await vm.toggleAllergen(5);
      expect(vm.selectedAllergenIds, contains(5));
    });

    test('toggling an ID twice removes it', () async {
      final vm = PersonalAllergenViewModel();
      await vm.loadSelections();
      await vm.toggleAllergen(5);
      await vm.toggleAllergen(5);
      expect(vm.selectedAllergenIds, isNot(contains(5)));
    });

    test('isSelected returns correct value', () async {
      final vm = PersonalAllergenViewModel();
      await vm.loadSelections();
      await vm.toggleAllergen(3);
      expect(vm.isSelected(3), isTrue);
      expect(vm.isSelected(7), isFalse);
    });

    test('persists selections across instances', () async {
      final vm1 = PersonalAllergenViewModel();
      await vm1.loadSelections();
      await vm1.toggleAllergen(2);
      await vm1.toggleAllergen(8);

      final vm2 = PersonalAllergenViewModel();
      await vm2.loadSelections();
      expect(vm2.selectedAllergenIds, containsAll([2, 8]));
    });

    test('notifies listeners on toggle', () async {
      final vm = PersonalAllergenViewModel();
      await vm.loadSelections();
      var notified = false;
      vm.addListener(() => notified = true);
      await vm.toggleAllergen(1);
      expect(notified, isTrue);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/milanrusimov/Documents/Projects/Flutter/serbia_open_data/alergeni && flutter test test/presentation/viewmodels/personal_allergen_view_model_test.dart`

Expected: Compilation error — file does not exist.

- [ ] **Step 3: Write minimal implementation**

Create `lib/presentation/viewmodels/personal_allergen_view_model.dart`:

```dart
// ABOUTME: Manages the user's personal allergen selections with local persistence.
// ABOUTME: Provides toggle, query, and load/save via SharedPreferences.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PersonalAllergenViewModel extends ChangeNotifier {
  static const String _storageKey = 'personal_allergen_ids';

  Set<int> _selectedIds = {};

  Set<int> get selectedAllergenIds => Set.unmodifiable(_selectedIds);

  bool isSelected(int allergenId) => _selectedIds.contains(allergenId);

  Future<void> loadSelections() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_storageKey);
    if (stored != null) {
      final List<dynamic> decoded = jsonDecode(stored);
      _selectedIds = decoded.cast<int>().toSet();
    }
    notifyListeners();
  }

  Future<void> toggleAllergen(int allergenId) async {
    if (_selectedIds.contains(allergenId)) {
      _selectedIds.remove(allergenId);
    } else {
      _selectedIds.add(allergenId);
    }
    notifyListeners();
    await _saveSelections();
  }

  Future<void> _saveSelections() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_selectedIds.toList()));
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /Users/milanrusimov/Documents/Projects/Flutter/serbia_open_data/alergeni && flutter test test/presentation/viewmodels/personal_allergen_view_model_test.dart`

Expected: All 6 tests PASS.

- [ ] **Step 5: Commit**

```bash
cd /Users/milanrusimov/Documents/Projects/Flutter/serbia_open_data/alergeni
git add lib/presentation/viewmodels/personal_allergen_view_model.dart test/presentation/viewmodels/personal_allergen_view_model_test.dart
git commit -m "Add PersonalAllergenViewModel with toggle and persistence"
```

---

## Task 6: Register `PersonalAllergenViewModel` in `main.dart`

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Add provider registration**

In `lib/main.dart`, add the import:

```dart
import 'package:udahni/presentation/viewmodels/personal_allergen_view_model.dart';
```

In the `MultiProvider` children list (after the existing `MapViewModel` provider, around line 28), add:

```dart
        ChangeNotifierProvider(
          create: (_) => PersonalAllergenViewModel()..loadSelections(),
        ),
```

- [ ] **Step 2: Run analyze**

Run: `cd /Users/milanrusimov/Documents/Projects/Flutter/serbia_open_data/alergeni && flutter analyze`

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
cd /Users/milanrusimov/Documents/Projects/Flutter/serbia_open_data/alergeni
git add lib/main.dart
git commit -m "Register PersonalAllergenViewModel in MultiProvider"
```

---

## Task 7: Create Personal Allergen Selection Screen

**Files:**
- Create: `lib/presentation/screens/personal_allergen_screen.dart`

- [ ] **Step 1: Create the selection screen**

Create `lib/presentation/screens/personal_allergen_screen.dart`:

```dart
// ABOUTME: Screen where users mark which allergens personally affect them.
// ABOUTME: Lists all 26 allergens grouped by type with toggles for selection.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:udahni/core/helpers/allergen_type_helper.dart';
import 'package:udahni/core/helpers/severity_helper.dart';
import 'package:udahni/data/models/allergen.dart';
import 'package:udahni/presentation/viewmodels/home_view_model.dart';
import 'package:udahni/presentation/viewmodels/personal_allergen_view_model.dart';

class PersonalAllergenScreen extends StatelessWidget {
  const PersonalAllergenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final allergens = context.read<HomeViewModel>().allergens ?? [];
    final personalVm = context.watch<PersonalAllergenViewModel>();

    final grouped = <int, List<Allergen>>{};
    for (final allergen in allergens) {
      grouped.putIfAbsent(allergen.type, () => []).add(allergen);
    }

    final sortedTypeIds = grouped.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Moji alergeni'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: sortedTypeIds.length,
        itemBuilder: (context, sectionIndex) {
          final typeId = sortedTypeIds[sectionIndex];
          final typeAllergens = grouped[typeId]!
            ..sort((a, b) => a.localizedName.compareTo(b.localizedName));
          final typeName = AllergenTypeHelper.getLocalizedNameForType(typeId);
          final typeColor = AllergenTypeHelper.getColorForType(typeId);
          final typeIcon = AllergenTypeHelper.getIconForType(typeId);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Icon(typeIcon, color: typeColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      typeName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: typeColor,
                      ),
                    ),
                  ],
                ),
              ),
              ...typeAllergens.map((allergen) {
                final isSelected = personalVm.isSelected(allergen.id);
                final allergenicityColor =
                    SeverityHelper.allergenicityBaseColor(
                      allergen.allergenicityIndex,
                    );
                final allergenicityLabel = SeverityHelper.allergenicityLabel(
                  allergen.allergenicityIndex,
                );

                return ListTile(
                  title: Text(allergen.localizedName),
                  subtitle: Text(
                    allergen.name,
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: allergenicityColor.withAlpha(51),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          allergenicityLabel,
                          style: TextStyle(
                            fontSize: 10,
                            color: allergenicityColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: isSelected,
                        onChanged: (_) =>
                            personalVm.toggleAllergen(allergen.id),
                        activeColor: typeColor,
                      ),
                    ],
                  ),
                );
              }),
              if (sectionIndex < sortedTypeIds.length - 1)
                const Divider(height: 1),
            ],
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 2: Run analyze**

Run: `cd /Users/milanrusimov/Documents/Projects/Flutter/serbia_open_data/alergeni && flutter analyze`

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
cd /Users/milanrusimov/Documents/Projects/Flutter/serbia_open_data/alergeni
git add lib/presentation/screens/personal_allergen_screen.dart
git commit -m "Add personal allergen selection screen"
```

---

## Task 8: Add Personal Allergen Highlight to Top Allergens Card

**Files:**
- Modify: `lib/presentation/widgets/top_allergens_card.dart`
- Modify: `lib/presentation/screens/home_screen.dart`

- [ ] **Step 1: Add `isPersonal` flag to `TopAllergenItem`**

In `lib/presentation/widgets/top_allergens_card.dart`, add `isPersonal` to the `TopAllergenItem` class.

Add to the constructor parameters (after `this.trendIcon`):

```dart
    this.isPersonal = false,
```

Add to the fields (after `final IconData? trendIcon;`):

```dart
  final bool isPersonal;
```

- [ ] **Step 2: Add highlight styling to `_TopAllergenRow`**

In `_TopAllergenRow.build()`, wrap the existing `Padding` widget's content to add a highlight when `item.isPersonal` is true.

Replace the outer `Padding` return (line 133-214) in `_TopAllergenRow.build()` with:

```dart
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(8),
      decoration: item.isPersonal
          ? BoxDecoration(
              color: item.color.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
              border: Border(
                left: BorderSide(color: item.color, width: 3),
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (item.isPersonal) ...[
                      Icon(Icons.person, size: 14, color: item.color),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      '${item.index}. ${item.name}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: item.color.withAlpha(51),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.allergenicityLabel,
                        style: TextStyle(
                          fontSize: 9,
                          color: item.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (item.trendIcon != null) ...[
                      const SizedBox(width: 4),
                      Icon(item.trendIcon, size: 14, color: item.color),
                    ],
                  ],
                ),
              ),
              Text(
                '${item.value}',
                style: TextStyle(
                  color: item.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: item.value / maxValue,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(item.color),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                item.severityLabel,
                style: TextStyle(
                  color: item.color,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
```

- [ ] **Step 3: Wire personal allergen IDs into `HomeScreen`**

In `lib/presentation/screens/home_screen.dart`, add imports:

```dart
import 'package:udahni/presentation/viewmodels/personal_allergen_view_model.dart';
import 'package:udahni/presentation/screens/personal_allergen_screen.dart';
```

In the `build()` method, add a button to the AppBar actions. Replace the AppBar (lines 62-66):

```dart
      appBar: AppBar(
        title: const Text('Početna'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
      ),
```

with:

```dart
      appBar: AppBar(
        title: const Text('Početna'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Moji alergeni',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PersonalAllergenScreen(),
                ),
              );
            },
          ),
        ],
      ),
```

In `_buildTopAllergensSection()`, read the personal allergen IDs and pass `isPersonal` to each `TopAllergenItem`. Replace the method signature and the `items` mapping.

Change the method to accept personal IDs. Update the call site in `_buildBody` from:

```dart
              _buildTopAllergensSection(context, viewModel),
```

to:

```dart
              _buildTopAllergensSection(context, viewModel, context.watch<PersonalAllergenViewModel>().selectedAllergenIds),
```

Then update the method signature from:

```dart
  Widget _buildTopAllergensSection(
    BuildContext context,
    HomeViewModel viewModel,
  ) {
```

to:

```dart
  Widget _buildTopAllergensSection(
    BuildContext context,
    HomeViewModel viewModel,
    Set<int> personalAllergenIds,
  ) {
```

In the `TopAllergenItem` constructor call inside the `.map()`, add the `isPersonal` parameter:

```dart
      return TopAllergenItem(
        index: index,
        name: allergen.localizedName,
        allergenicityLabel: allergen.allergenicityDisplayLocalized,
        color: color,
        value: conc.value,
        severityLabel: severityLabel,
        trendIcon: trendIcon,
        isPersonal: personalAllergenIds.contains(allergen.id),
      );
```

- [ ] **Step 4: Run analyze and all tests**

Run: `cd /Users/milanrusimov/Documents/Projects/Flutter/serbia_open_data/alergeni && flutter analyze && flutter test`

Expected: No errors, all tests pass.

- [ ] **Step 5: Commit**

```bash
cd /Users/milanrusimov/Documents/Projects/Flutter/serbia_open_data/alergeni
git add lib/presentation/widgets/top_allergens_card.dart lib/presentation/screens/home_screen.dart
git commit -m "Highlight personal allergens in top allergens card"
```

---

## Task 9: Create First-Run Hint Widget

**Files:**
- Create: `lib/presentation/widgets/first_run_hint.dart`

- [ ] **Step 1: Create the dismissable hint widget**

Create `lib/presentation/widgets/first_run_hint.dart`:

```dart
// ABOUTME: A dismissable tooltip-style hint shown to first-time users.
// ABOUTME: Displays a short message above a child widget, dismissed by tapping.

import 'package:flutter/material.dart';

class FirstRunHint extends StatelessWidget {
  final String message;
  final bool visible;
  final VoidCallback onDismiss;
  final Widget child;

  const FirstRunHint({
    super.key,
    required this.message,
    required this.visible,
    required this.onDismiss,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        if (visible)
          GestureDetector(
            onTap: onDismiss,
            child: Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      message,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.close,
                    size: 14,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
```

- [ ] **Step 2: Run analyze**

Run: `cd /Users/milanrusimov/Documents/Projects/Flutter/serbia_open_data/alergeni && flutter analyze`

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
cd /Users/milanrusimov/Documents/Projects/Flutter/serbia_open_data/alergeni
git add lib/presentation/widgets/first_run_hint.dart
git commit -m "Add FirstRunHint widget for contextual first-launch tips"
```

---

## Task 10: Implement Smart First-Run Experience

**Files:**
- Modify: `lib/presentation/screens/home_screen.dart`

- [ ] **Step 1: Add first-run state and auto-location logic**

In `lib/presentation/screens/home_screen.dart`, add import:

```dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udahni/presentation/widgets/first_run_hint.dart';
```

Add state fields to `_HomeScreenState` (after `static const double _sectionSpacing = 16;`):

```dart
  static const String _firstLaunchKey = 'first_launch_completed';
  bool _showHints = false;
  bool _locationHintDismissed = false;
  bool _summaryHintDismissed = false;
  bool _allergensHintDismissed = false;
```

- [ ] **Step 2: Add first-run check to `initState`**

Replace the existing `initState()` method with:

```dart
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final viewModel = context.read<HomeViewModel>();
      if (viewModel.shouldShowOffSeasonDialog) {
        _showOffSeasonDialog(context);
        viewModel.hasShownOffSeasonMessage = true;
      }
      _checkFirstLaunch(viewModel);
    });
  }

  Future<void> _checkFirstLaunch(HomeViewModel viewModel) async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool(_firstLaunchKey) ?? false;
    if (completed) return;

    await prefs.setBool(_firstLaunchKey, true);

    if (!mounted) return;
    setState(() => _showHints = true);

    try {
      final nearestLocation = await viewModel.selectNearestLocationFromDevice();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Izabrana je najbliža lokacija: ${nearestLocation.name}',
          ),
        ),
      );
    } catch (_) {
      // Location detection failed — graceful degradation, no error shown.
    }
  }
```

- [ ] **Step 3: Wrap key cards with `FirstRunHint`**

In `_buildBody()`, wrap the `LocationSelectorCard` with a hint. Replace:

```dart
            LocationSelectorCard(
              locations: viewModel.locations!,
              selectedLocation: viewModel.selectedLocation,
              isMyLocationLoading: viewModel.isLocatingNearestLocation,
              onLocationChanged: viewModel.selectLocation,
              onMyLocationPressed: () async {
```

with:

```dart
            FirstRunHint(
              message: 'Promenite stanicu u bilo kom trenutku',
              visible: _showHints && !_locationHintDismissed,
              onDismiss: () => setState(() => _locationHintDismissed = true),
              child: LocationSelectorCard(
                locations: viewModel.locations!,
                selectedLocation: viewModel.selectedLocation,
                isMyLocationLoading: viewModel.isLocatingNearestLocation,
                onLocationChanged: viewModel.selectLocation,
                onMyLocationPressed: () async {
```

Add the closing parenthesis for `FirstRunHint` after the `LocationSelectorCard`'s closing parenthesis (after the existing `)` that closes `LocationSelectorCard`, before the `const SizedBox`):

```dart
            ),
```

Wrap `_buildWeeklySummaryCard(context, viewModel)` with a hint. Replace:

```dart
              _buildWeeklySummaryCard(context, viewModel),
```

with:

```dart
              FirstRunHint(
                message: 'Ukupni nivo polena za vašu oblast ove nedelje',
                visible: _showHints && !_summaryHintDismissed,
                onDismiss: () => setState(() => _summaryHintDismissed = true),
                child: _buildWeeklySummaryCard(context, viewModel),
              ),
```

Wrap the top allergens section. Replace:

```dart
              _buildTopAllergensSection(context, viewModel, context.watch<PersonalAllergenViewModel>().selectedAllergenIds),
```

with:

```dart
              FirstRunHint(
                message: 'Vaši najzastupljeniji alergeni rangirani po koncentraciji',
                visible: _showHints && !_allergensHintDismissed,
                onDismiss: () => setState(() => _allergensHintDismissed = true),
                child: _buildTopAllergensSection(context, viewModel, context.watch<PersonalAllergenViewModel>().selectedAllergenIds),
              ),
```

- [ ] **Step 4: Run analyze and all tests**

Run: `cd /Users/milanrusimov/Documents/Projects/Flutter/serbia_open_data/alergeni && flutter analyze && flutter test`

Expected: No errors, all tests pass.

- [ ] **Step 5: Commit**

```bash
cd /Users/milanrusimov/Documents/Projects/Flutter/serbia_open_data/alergeni
git add lib/presentation/screens/home_screen.dart
git commit -m "Add smart first-run experience with auto-location and hints"
```

---

## Task 11: Final Integration Test and Cleanup

**Files:**
- All modified files (verification only)

- [ ] **Step 1: Run full test suite**

Run: `cd /Users/milanrusimov/Documents/Projects/Flutter/serbia_open_data/alergeni && flutter test`

Expected: All tests pass.

- [ ] **Step 2: Run static analysis**

Run: `cd /Users/milanrusimov/Documents/Projects/Flutter/serbia_open_data/alergeni && flutter analyze`

Expected: No errors (info-level hints are acceptable).

- [ ] **Step 3: Verify the app builds**

Run: `cd /Users/milanrusimov/Documents/Projects/Flutter/serbia_open_data/alergeni && flutter build apk --debug`

Expected: Build succeeds.

- [ ] **Step 4: Verify ABOUTME comments on all new files**

Check that these files start with ABOUTME comments:
- `lib/core/errors/app_error.dart`
- `lib/presentation/viewmodels/personal_allergen_view_model.dart`
- `lib/presentation/screens/personal_allergen_screen.dart`
- `lib/presentation/widgets/first_run_hint.dart`
- `lib/presentation/widgets/error_state.dart` (updated)
- `test/core/errors/app_error_test.dart`
- `test/presentation/viewmodels/personal_allergen_view_model_test.dart`

- [ ] **Step 5: Commit any cleanup**

If any fixes were needed:

```bash
cd /Users/milanrusimov/Documents/Projects/Flutter/serbia_open_data/alergeni
git add -A
git commit -m "Final cleanup for production readiness features"
```
