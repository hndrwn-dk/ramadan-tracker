# Superpowers workflow artifacts

This folder holds design specs and implementation plans produced by the [Superpowers](https://github.com/obra/superpowers) plugin workflow.

| Folder | Skill | Contents |
|--------|-------|----------|
| `specs/` | `brainstorming` | Approved design documents (`YYYY-MM-DD-<topic>-design.md`) |
| `plans/` | `writing-plans` | Step-by-step implementation plans with TDD tasks |

Cursor rules in `.cursor/rules/superpowers-workflow.mdc` wire these paths into the agent. Git worktrees for isolated feature work live in `.worktrees/` (gitignored).

Start a feature chat with: *"Use Superpowers brainstorming for …"*
