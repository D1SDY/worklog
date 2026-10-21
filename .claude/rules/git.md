# Git conventions

- **Branch:** `claude/{taskID}-{task-name-kebab-case}` —
  e.g. `claude/WORLOG-002-training-session-list`.
- **Base branch:** `develop`. `main` is the release branch and is not a PR target.
- **Commits:** Conventional Commits scoped by story ID —
  `feat(WORLOG-002): add training session list`.
  Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `ci`.
- **PR title:** `{taskID}: {Story name}`.
- **PR body:** from `.github/pull_request_template.md` — story link, acceptance
  criteria as a checklist, gate results, preview URL.
- One story per branch. Do not bundle unrelated changes.
