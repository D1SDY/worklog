# Testing

- **Widget test per acceptance criterion** where the criterion is observable in
  the UI. A criterion with no test is not delivered.
- **Unit test per non-trivial pure function** — enums with behaviour, mappers,
  validators, formatters.
- Loading, empty, and error states are part of every screen that touches async
  data, and each gets a test. No silent `catch {}`.
- Verify scroll behaviour in widget tests with `tester.drag`. Synthetic wheel
  events do not reach a Flutter web canvas.
- Tests must not depend on network. `google_fonts` fetches at runtime — call
  `TestWidgetsFlutterBinding.ensureInitialized()` and set
  `GoogleFonts.config.allowRuntimeFetching = false`.

## Coverage

`flutter test --coverage` writes `coverage/lcov.info`. The line rate must meet
the floor in `.github/coverage-floor`. Coverage instruments `lib/` only; scripts
under `tool/` are outside it by design.

The floor ratchets upward. Raising it is a PR, never a silent edit.
