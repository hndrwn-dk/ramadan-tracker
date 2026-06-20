# Agent guide — Ramadan Tracker

Index for **new Cursor agent chats**. Rules in `.cursor/rules/` load automatically.

**Superpowers:** Plugin enabled in `.cursor/settings.json`. Rule `superpowers-workflow` — mandatory skill pipeline (brainstorm → worktree → plan → TDD → verify). Artifacts in `docs/superpowers/`.

## Always-on rules

| Rule | Topic |
|------|--------|
| [superpowers-workflow](.cursor/rules/superpowers-workflow.mdc) | Superpowers skill pipeline, artifact paths, verification |
| [project-overview](.cursor/rules/project-overview.mdc) | App identity, stack, folder map |
| [git-require-approval](.cursor/rules/git-require-approval.mdc) | Never commit/push to main unless user asks |

## File-scoped rules

| Rule | When |
|------|------|
| [flutter-codebase](.cursor/rules/flutter-codebase.mdc) | All `lib/**` |

## Superpowers workflow

1. **brainstorming** — design in `docs/superpowers/specs/`
2. **using-git-worktrees** — feature branch in `.worktrees/`
3. **writing-plans** — tasks in `docs/superpowers/plans/`
4. **test-driven-development** + **verification-before-completion** — `flutter test` / `flutter analyze`
5. **finishing-a-development-branch** — merge / PR / keep / discard

Invoke: `/brainstorm`, `/write-plan`, `/execute-plan`

## Key docs

| File | Purpose |
|------|---------|
| [README.md](README.md) | Features, setup, architecture |
| [docs/superpowers/README.md](docs/superpowers/README.md) | Design specs and implementation plans |

## Suggested agent split

| Chat | Focus |
|------|--------|
| Agent A | Today / Month / habit logging UX |
| Agent B | Insights charts and obligations |
| Agent C | Sunnah fasting + widget |
| Agent D | Drift schema / migrations |

Do not mix large schema migrations with unrelated UI work in one chat.
