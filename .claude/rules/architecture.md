# Architecture

Layered, dependencies pointing inward only:

- `lib/ui/` — widgets and view models.
- `lib/domain/` — models and pure business rules.
- `lib/data/` — repositories and services.

`lib/ui/` may depend on `lib/domain/`. `lib/data/` may depend on `lib/domain/`.
`lib/domain/` depends on neither. A widget that calls HTTP directly, or a domain
model that imports a widget, is a `MAJOR` finding.

Feature folders under `lib/ui/<feature>/widgets/`. Shared UI in `lib/ui/core/`.

Adding a dependency is a decision, not a reflex. Check whether the framework
already does it; search pub.dev through the Dart MCP server rather than
guessing; prefer `flutter.dev`-published packages; justify it in one line in
the PR body — what it replaces and why hand-rolling is worse.
