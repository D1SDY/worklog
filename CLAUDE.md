# worklog — Flutter mobile app

Flutter application (`name: worklog`). Target: **Android + iOS**. Web is scaffolded but is
not the primary target.

## Toolchain

- Flutter 3.47.2 (stable), Dart 3.13.2 — pubspec `sdk: ^3.13.2`
- Lints: `flutter_lints` via `analysis_options.yaml`
- AI tooling: `dart-flutter` Claude plugin (Dart MCP server + Flutter/Dart skills)

## Commands

```bash
flutter pub get
flutter analyze
dart format .
flutter test                       # unit + widget tests
flutter run -d <device>            # `flutter devices` to list
flutter build apk --release
flutter build ipa --release        # macOS only
```

## Use the Dart MCP server, not the shell, for these

The `dart-mcp-server` MCP server is connected. Prefer its tools — they are faster and
return structured results:

| Task | Use | Not |
|---|---|---|
| Static analysis | `analyze_files` (`applyFixes: true` to auto-fix) | `flutter analyze` |
| Find a package | `pub_dev_search` | web search |
| Add/remove deps | `pub` | `flutter pub add` |
| Read a dependency's source | `read_package_uris`, `rip_grep_packages` (`package:` and `package-root:` URIs) | hunting in `.pub-cache` |
| Connect to a running app | `dtd` | — |
| Apply changes to a running app | `hot_reload` / `hot_restart` | restarting the app |
| Runtime exceptions | `get_runtime_errors` | reading scrollback |
| Widget tree / layout debugging | `widget_inspector` | guessing |
| Driving the UI in tests | `flutter_driver_command` | — |

## Hot reload rule

After editing any `.dart` file under `lib/`, connect to a running app with `dtd` if not
already connected, then:

- `hot_reload` — UI/widget changes, `build` methods, simple method bodies.
- `hot_restart` — `main()`, `initState`, global/static state, or fundamental logic changes.

Skip both for comment/whitespace-only edits, and for files outside `lib/` (`test/`,
`integration_test/`, `example/`).

## Skills

The `dart-flutter` plugin ships skills — invoke them instead of improvising:

- Architecture / project structure → `flutter-apply-architecture-best-practices`
- Navigation, deep links → `flutter-setup-declarative-routing`
- Adaptive phone/tablet layouts → `flutter-build-responsive-layout`
- `RenderFlex overflowed`, unbounded constraints → `flutter-fix-layout-issues`
- Widget tests → `flutter-add-widget-test`; integration tests → `flutter-add-integration-test`
- Unit tests → `dart-add-unit-test`; mocks → `dart-generate-test-mocks`
- REST calls → `flutter-use-http-package`; models → `flutter-implement-json-serialization`
- i18n → `flutter-setup-localization`
- Runtime stack traces → `dart-fix-runtime-errors`
- Analysis/lints → `dart-run-static-analysis`; version conflicts → `dart-resolve-package-conflicts`

Skills bundled by pub dependencies are installed with `dart run skills@ get --agent claude`
(re-run after adding dependencies).

## Conventions

- Layered architecture: `lib/ui/` (widgets + view models), `lib/domain/` (models),
  `lib/data/` (repositories + services). Dependencies point inward only.
- `const` constructors wherever possible; prefer composition over deep widget nesting.
- No business logic in `build()`.
- Mobile-first: verify layouts at phone width before tablet/desktop.
- Every feature lands with a widget test; every non-trivial pure function with a unit test.
- Run `analyze_files` and `flutter test` before claiming work is done.

## Definition of Done

No story is done until **all four gates pass**. Run them in this order; a
failure at any gate means the story is still in progress.

0. **UI rules met** — this is a baseline acceptance criterion on **every**
   story that renders anything, whether or not the story restates it. The
   canonical spec is 📐 UI Component Rules in Notion
   (`https://app.notion.com/p/3d15b5635132811aad56df8c1e6c53f0`), plus the
   `🎨 UI/UX Consistency Notes` on the story's own page. Design tokens,
   Ukrainian UI copy, spacing/radius scale, and component patterns are not
   optional polish and are not deferrable to a later story. Treat a violation
   exactly like a failing test.
1. **Analyzer clean** — `analyze_files` (Dart MCP) returns **zero diagnostics**.
   Not "zero errors": lint violations surface as `info`, and they count.
2. **Tests green** — `flutter test` passes with no failures and no skips.
3. **App runs** — `flutter run -d chrome` boots with no runtime errors, and
   `get_runtime_errors` comes back empty.

Report the actual command output when claiming a gate passed. "Should pass" is
not a pass.

> **Known gap:** `android/` and `ios/` are not scaffolded, so gate 3 is
> Chrome-only today. The mobile run gate is deferred, not satisfied — do not
> claim Android/iOS verification until those platforms exist.

## Member order

Constructors first (this half `sort_constructors_first` does enforce); the
rest is a written convention enforced in review. Within every class:

1. Static constants
2. Static fields
3. Unnamed constructor
4. Named constructors
5. Factory constructors
6. Final instance fields
7. Non-final instance fields
8. Getters and setters
9. Lifecycle methods **in call order** — `initState`,
   `didChangeDependencies`, `didUpdateWidget`, `dispose`
10. `build()`
11. Public methods
12. Private methods (`_`-prefixed)

Import order (`directives_ordering` enforces this): `dart:` → `package:` →
relative, alphabetized within each group.

## Story workflow

Stories live in the **Sprint Backlog** database in Notion. Work them one at a
time via the `story-workflow` skill in `.claude/skills/story-workflow/`, which
carries the full loop and the accumulated lessons-learned log.
