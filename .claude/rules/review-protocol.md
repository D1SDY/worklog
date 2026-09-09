# Review protocol

## Severity

| Severity | Meaning | Blocks the gate? |
|---|---|---|
| `BLOCKER` | Broken behaviour, a missed acceptance criterion, or a Gate 0 UI violation | Yes |
| `MAJOR` | Wrong layering, missing test for delivered behaviour, unhandled error state | Yes |
| `MINOR` | Naming, duplication, a clearer construction | No |
| `NIT` | Preference | No |

A reviewer's verdict is `BLOCK` if it filed any `BLOCKER` or `MAJOR`, else `PASS`.

## Category

Every finding carries a category:

- `code` — something the dev agent could fix in this repo.
- `infrastructure` — a broken precondition: unreachable MCP server, expired
  token, preview URL that will not load, a reviewer job that crashed.

An `infrastructure` blocker stops the gate but does **not** trigger autofix and
does **not** consume a review iteration. A dev agent cannot fix a credential.

## Verdict file

Each reviewer writes `.review/{role}.json` where role is `ba`, `qa`, or `design`:

    {
      "role": "qa",
      "verdict": "BLOCK",
      "findings": [
        {
          "severity": "BLOCKER",
          "category": "code",
          "file": "lib/ui/training/widgets/training_screen.dart",
          "line": 42,
          "summary": "One line, what is wrong",
          "why": "Why it matters, and what correct looks like"
        }
      ]
    }

The artifact is the source of truth for the gate. The human-readable review is
posted separately as a PR comment and is never parsed.

A missing or unparseable verdict file is treated as an `infrastructure` blocker.
A reviewer that crashed must never read as a pass.

## Iteration cap

Three review iterations. On the third `BLOCK` the pipeline stops and asks the
human to arbitrate rather than fixing again.
