# Code style

## Comments

- **No explanatory `//` comments** inside function bodies or immediately above
  statements. Do not add them unless the user explicitly asked for comments.
  Code that needs a comment to be understood usually needs a better name.
- `///` dartdoc on public API is **required**. It is documentation, not a
  comment, and the analyzer treats it as such.
- `// ignore:` and `// ignore_for_file:` are permitted, and must carry a reason.
- License headers are permitted.
- A violation is a `BLOCKER`, treated exactly like a failing test.

## Dart

- `const` constructors and `const` literals wherever the analyzer permits.
- Single quotes. Trailing commas on every multi-line argument list.
- Declare return types explicitly, including `void`.
- `final` for locals that are never reassigned.
- Prefer composition over deep widget nesting.
- No business logic in `build()`.

## Member order

Static constants → static fields → unnamed constructor → named constructors →
factory constructors → final instance fields → non-final instance fields →
getters and setters → lifecycle methods in call order (`initState`,
`didChangeDependencies`, `didUpdateWidget`, `dispose`) → `build()` → public
methods → private methods.

The `sort_constructors_first` lint enforces the constructor half of this
order; the rest is a written convention enforced in review.

## Import order

`dart:` → `package:` → relative, alphabetised within each group.
`directives_ordering` enforces this.
