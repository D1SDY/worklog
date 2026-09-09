# UI rules — Gate 0

Meeting these is a baseline acceptance criterion on **every** story that renders
anything, whether or not the story restates it. A violation is a `BLOCKER`.

## Source of truth

1. `lib/ui/core/theme/app_tokens.dart` — the in-repo token definitions. Widgets
   reference these. A raw hex colour, spacing number, or radius written inline
   in a widget is a bug, not a shortcut.
2. 📐 UI Component Rules — https://app.notion.com/p/3d15b5635132811aad56df8c1e6c53f0
   The upstream authority. It outranks Flutter and Material defaults, and it
   outranks a story's own prose. Where a story and this page disagree, the page
   wins and the reviewer says so.
3. 🎨 UI/UX Design Analysis — https://app.notion.com/p/3d15b5635132811cbb61d1708dd774e0
   Screen-by-screen reasoning behind the tokens.
4. 🎨 UI/UX Consistency Notes — on the story's own page in the Sprint Backlog,
   when present.

Reuse before inventing. If a button, card, modal, pill, badge, or toast pattern
already exists, use it — do not create a variant. A genuinely new pattern is
designed from existing tokens and added to the Notion page *before* use; adding
one is an edit to a shared page, so ask first.

## Standing facts that are easy to get wrong

- **The UI language is Ukrainian.** Bottom-nav labels are exactly: Головна ·
  Тренування · Статистика · Досягнення · Профіль. English names appearing in a
  story description identify the tabs for the reader; they are not UI copy.
- **Dark-first, not a Material light default.** `ColorScheme.fromSeed` with an
  arbitrary seed colour is wrong.
- **Red is reserved** for errors and destructive actions. An unfavourable trend
  uses orange. Never hardcode "down is bad" — derive it from the user's goal
  direction.
- **Two fonts by role:** Inter for all UI text, JetBrains Mono for every numeric
  value — weights, reps, stats, axis labels.
- **Spacing comes from the 4px scale** (`AppSpacing`). No arbitrary values.
- **Radius:** 8 inputs, 12 cards/chips/buttons, 16 modals and primary CTA,
  circular avatars via `BoxShape.circle`.
- **Bottom nav** is 56px, icon above label, active tab in `accentBlue`, inactive
  muted, scroll position preserved per tab, sitting on `bgSecondary`.
- **Mobile-first:** verify layouts at phone width before tablet/desktop.
