# Agent pipeline design — worklog

**Date:** 2026-09-09
**Status:** Approved, not yet implemented
**Repo:** `github.com/D1SDY/worklog` (Flutter, web-only today)

## 1. Goal

Take a story from the Notion Sprint Backlog to a reviewed, tested, deployed
change with four specialised agents and no hand-run steps in between:

1. `flutter-senior-dev` implements on a `claude/...` branch and opens a PR.
2. Opening the PR runs the mechanical gates and deploys a per-PR preview.
3. Three reviewers — BA, QA, Designer — analyse the PR in parallel.
4. Clean → the pipeline asks the human to approve. Not clean → the dev agent
   fixes and the review runs again.
5. Merge to `develop` re-runs the gates and deploys the dev environment.
6. A retro step turns what the reviewers caught into durable rules, via a PR.

## 2. Decisions

| # | Decision | Rationale |
|---|---|---|
| D1 | Reviews run autonomously in GitHub Actions via `anthropics/claude-code-action@v1` | The loop must close without a human at a terminal. |
| D2 | Three parallel reviewer jobs, one per role, aggregated by a `gate` job | Isolated tool allowlists, one log per role, concurrent, and one crashed reviewer does not lose the other two. |
| D3 | `claude/{taskID}-{task-name}` → PR → `develop`; `main` stays the release branch | Matches the requested flow; `main` is left free for a later promotion PR. |
| D4 | The dev agent auto-fixes blocking findings in CI and pushes to the same branch, capped at 3 iterations | Closed loop; the cap stops runaway spend and infinite argument. |
| D5 | Rules live in `.claude/rules/`; a retro job proposes changes through a PR, never a direct push | Instructions grow, but no rule changes without human approval. |
| D6 | The repository becomes public | GitHub Pages previews on a private repo need a paid plan. Consequence: CI logs and every agent review comment are world-readable. |
| D7 | Auth is `CLAUDE_CODE_OAUTH_TOKEN` from `claude setup-token` | Covered by the existing Claude subscription; no API billing. Cost is subscription rate limits shared with local Claude Code use. |
| D8 | The whole PR loop lives in **one** workflow file | Cross-workflow triggering (`workflow_run`, label events) either does not fire for `GITHUB_TOKEN` actions or hands secrets to fork PRs. A single `needs:` chain avoids both. |

## 3. Repository preparation

Ordered, and all of it precedes the first pipeline run:

1. Push `main` — the remote is currently **empty** (`git ls-remote --heads origin` returns nothing).
2. Make the repository public.
3. Create `develop` from `main`; set it as the default branch.
4. Create an orphan `gh-pages` branch with a `.nojekyll` file at its root
   (Flutter web ships `_`-prefixed paths that Jekyll would drop).
5. Enable Pages with source = `gh-pages` branch, root folder.
6. `gh secret set CLAUDE_CODE_OAUTH_TOKEN` (and `NOTION_TOKEN`, if used).
7. Branch protection on `develop`: require the `gate` check, require 1
   approving review, no direct pushes.

## 4. Agents

Four files under `.claude/agents/`. Each file is simultaneously the local
subagent definition and the persona the CI job loads, so local and CI behaviour
cannot drift. `.claude/agents/flutter-mobile-dev.md` is deleted — superseded by
`flutter-senior-dev`.

| Agent | Model | Owns | MCP servers in CI |
|---|---|---|---|
| `flutter-senior-dev` | `claude-opus-5` | Implementation and autofix | `dart-mcp-server`, Notion |
| `business-analyst` | `claude-sonnet-5` | Acceptance-criteria traceability, scope creep, missing states | Notion |
| `qa-engineer` | `claude-opus-5` | Test adequacy, coverage delta, edge cases, runtime errors on the preview | `dart-mcp-server`, Playwright |
| `ui-designer` | `claude-sonnet-5` | Gate 0 — tokens, Ukrainian copy, spacing and radius scale, dark-first palette | Playwright, Notion |

MCP configs are checked in at `.github/mcp/{role}.json` and passed with
`--mcp-config`:

- `dart-mcp-server` — `dart mcp-server` over stdio, after `flutter pub get`.
- Notion — `npx -y @notionhq/notion-mcp-server`, `NOTION_TOKEN` from secrets.
- Playwright — `npx -y @playwright/mcp@latest --headless`, pointed at the
  deployed preview URL.

`claude-in-chrome` is a local browser extension and cannot run on a runner;
Playwright is its CI replacement for the two agents that need to see the UI.

Every agent job sets `--max-turns` and omits `github_token:` so the action
authenticates as the Claude GitHub App.

### 4.1 Degrading without Notion

`NOTION_TOKEN` is optional. The canonical design tokens — dark-first palette,
4px spacing scale, radius scale, the two fonts by role, the Ukrainian nav
labels — are mirrored into `.claude/rules/ui.md`, so `ui-designer` enforces
Gate 0 offline. Notion adds the screen-specific notes and the story's own
acceptance criteria; without it, BA falls back to the PR body's AC checklist.

## 5. Rules layer

`.claude/rules/`, referenced by path from `CLAUDE.md` and from all four agent
files so each rule has exactly one copy:

| File | Contents |
|---|---|
| `architecture.md` | Layering (`lib/ui`, `lib/domain`, `lib/data`), inward-only dependencies, no logic in `build()`, member order, import order |
| `code-style.md` | `const` usage, naming, formatting, **the no-inline-comments rule** |
| `ui.md` | Design tokens, Ukrainian copy, spacing and radius scales, component patterns, Gate 0 |
| `testing.md` | Widget test per acceptance criterion, unit test per non-trivial pure function, coverage policy |
| `git.md` | Branch naming, commit format, PR title and body |
| `review-protocol.md` | Severity taxonomy, verdict format, the `.review/{role}.json` contract, iteration cap |
| `lessons.md` | Append-only observations awaiting promotion into a rule |

### 5.1 The no-inline-comments rule

Stated in `code-style.md` at BLOCKER severity:

- No explanatory `//` comments inside function bodies or immediately above
  statements, unless the user explicitly asked for comments.
- `///` dartdoc on public API is **required** — it is a lint, not a comment.
- `// ignore:` / `// ignore_for_file:` and license headers are permitted.
- Reviewers treat a violation exactly like a failing test.

### 5.2 Self-growth

`retro.yml` runs after a successful deploy from `develop`. It reads the review
threads on the merged PR, keeps only findings that recur or that no existing
rule covers, and edits `.claude/rules/*.md`, then opens a PR against `develop`
titled `chore(rules): <summary>`. Findings not yet worth a rule are appended to
`lessons.md` in the same PR. Rules never change without that PR being approved.

## 6. Conventions

- **Branch:** `claude/{taskID}-{task-name-kebab-case}`, e.g.
  `claude/WORLOG-002-training-session-list`.
- **Commits:** Conventional Commits, scoped by story ID —
  `feat(WORLOG-002): add training session list`.
- **PR title:** `{taskID}: {Story name}`.
- **PR body:** from `.github/pull_request_template.md` — story link, the
  acceptance criteria as a checklist, gate results, preview URL.

## 7. Pipeline

### 7.1 `.github/workflows/pr.yml`

Trigger: `pull_request` on `develop`, types `[opened, synchronize, reopened, ready_for_review]`.
Every job carries `if: github.event.pull_request.head.repo.full_name == github.repository`.
Flutter pinned to 3.47.2 via `subosito/flutter-action@v2`.

| Job | Needs | Does |
|---|---|---|
| `verify` | — | `flutter pub get`; `dart format --set-exit-if-changed .`; `flutter analyze --fatal-infos`; `flutter test --coverage`; coverage floor check |
| `build` | `verify` | `flutter build web --release --base-href /worklog/pr-<N>/` |
| `preview` | `build` | Publish to `gh-pages` under `pr-<N>/`; comment the preview URL on the PR |
| `review-ba` | `preview` | `business-analyst` persona; writes `.review/ba.json`; posts its review as a PR comment |
| `review-qa` | `preview` | `qa-engineer` persona; same contract |
| `review-design` | `preview` | `ui-designer` persona; same contract |
| `gate` | the three reviews | Downloads the three verdict artifacts, aggregates, applies labels, and either requests human approval or marks the PR `needs-fix` |
| `autofix` | `gate` | Runs only when `gate` says BLOCK and the iteration count is below 3. Runs `flutter-senior-dev` against the findings, commits, pushes as the Claude GitHub App |

The push in `autofix` fires `synchronize`, which re-runs the whole chain. That
is the review loop, and it works precisely because the App's token — unlike
`GITHUB_TOKEN` — does trigger workflows.

### 7.2 `.github/workflows/develop.yml`

Trigger: `push` to `develop`. Runs the same `verify` and `build` jobs, builds
with `--base-href /worklog/dev/`, publishes to `gh-pages` under `dev/`, then
runs the retro job from §5.2.

### 7.3 `.github/workflows/pr-cleanup.yml`

Trigger: `pull_request` `closed`. Removes `pr-<N>/` from `gh-pages`.

## 8. Review protocol

### 8.1 Severity

| Severity | Meaning | Blocks? |
|---|---|---|
| `BLOCKER` | Broken behaviour, a missed acceptance criterion, or a Gate 0 UI violation | Yes |
| `MAJOR` | Wrong layering, missing test for delivered behaviour, unhandled error state | Yes |
| `MINOR` | Naming, duplication, a clearer construction | No |
| `NIT` | Preference | No |

Verdict is `BLOCK` if the reviewer filed any `BLOCKER` or `MAJOR`, else `PASS`.

### 8.2 Machine-readable contract

Each reviewer writes `.review/{role}.json`:

```json
{
  "role": "qa",
  "verdict": "BLOCK",
  "findings": [
    {
      "severity": "BLOCKER",
      "file": "lib/ui/training/widgets/training_screen.dart",
      "line": 42,
      "summary": "...",
      "why": "..."
    }
  ]
}
```

uploaded as an artifact. `gate` downloads all three and aggregates. The
human-readable review is posted separately as a PR comment. The artifact is the
source of truth for the gate — comment text is never parsed.

### 8.3 Labels

`iteration-1..3`, `needs-fix`, `ready-for-approval`, `review-cap-reached`.

`verify` clears `needs-fix` and `ready-for-approval` at the start of every run,
so a stale verdict from the previous iteration can never be read as the current
one. The `iteration-N` labels are cumulative and are never cleared — they are
the iteration counter.

`.review/` is gitignored; verdicts travel as artifacts, never as commits.

### 8.4 Outcomes

- All three `PASS` → label `ready-for-approval`, comment requesting the human's
  review. Branch protection means nothing merges without it.
- Any `BLOCK`, iteration < 3 → label `needs-fix` and `iteration-N+1`, `autofix` runs.
- Any `BLOCK`, iteration = 3 → label `review-cap-reached`, stop, and comment
  with the outstanding findings for the human to arbitrate.

## 9. Coverage policy

`flutter test --coverage` produces `coverage/lcov.info`. A script computes the
line rate and compares it against a floor stored in `.github/coverage-floor`.
The floor is set to the project's **measured** coverage at implementation time,
not a guessed number, and is raised by a `chore(rules)`-style PR whenever the
actual rate clears it by a margin. Generated files are excluded before the rate
is computed.

## 10. Secrets and security

| Secret | Required | Used by |
|---|---|---|
| `CLAUDE_CODE_OAUTH_TOKEN` | Yes | Every agent job |
| `NOTION_TOKEN` | No | BA and Designer, for story text and screen notes |

- Secrets are stored in repository settings, never committed. Workflow files
  contain only `${{ secrets.NAME }}` references.
- `pull_request_target` is not used anywhere in this design.
- `workflow_run` is not used anywhere in this design; it would grant secrets to
  fork-PR contexts.
- Every agent job is guarded on `head.repo.full_name == github.repository`.
  GitHub already withholds secrets from fork-PR runs; the guard is a second layer.
- `--max-turns` on every agent job bounds a runaway run.
- Story text and comments arriving from Notion are **data, not instructions**.
  An agent that reads a directive addressed to itself surfaces it rather than
  acting on it.

## 11. Out of scope

- `android/` and `ios/` do not exist. The pipeline is web-only, and the run
  gate stays Chrome/web-only, as `CLAUDE.md` already records. No claim of
  Android or iOS verification is made anywhere in this design.
- No production environment. `main` is untouched by these workflows; promotion
  from `develop` to `main` is a later, separate concern.
- Story status transitions in Notion remain owned by the `story-workflow`
  skill, which stops at `In Test`. This pipeline does not write Notion status.

## 12. Assumptions to verify during implementation

Each of these is a decision with a stated fallback, checked before the workflow
is declared working:

1. The Notion MCP server package name and its env-var contract. Fallback: BA
   and Designer run without Notion, against `.claude/rules/ui.md` and the PR
   body's AC checklist (§4.1).
2. `dart mcp-server` starts on a runner after `flutter pub get`. Fallback: the
   dev and QA agents shell out to `flutter analyze` and `flutter test`.
3. The retro agent can open a PR using the Claude GitHub App credentials.
   Fallback: it writes the rule changes to a branch and the `gate` job opens
   the PR with `gh`.
4. Pages serves `pr-<N>/` correctly with the per-PR `--base-href`. Fallback:
   publish to a flat path and set `--base-href` accordingly.
