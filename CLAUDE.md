# lipost — the `lipost` node of The Firm

> `CLAUDE.md` is mirrored at `AGENTS.md` — edit both.

## Building a feature → SOP-12 (inherited from the Firm apex)

This repo's build procedure is the Firm's **apex SOP-12 — "Build a codebase"**, inherited via the firm
governance cascade. The agent governing this repo **must follow it for any code build, without being told**.
Shape: **spec → CEO green-light → autonomous subagent build → docs + tests → ship.**

1. Write + self-review the **spec** at `specs/YYYY-MM-DD-<topic>-design.md`.
2. **Present the spec to the CEO and PAUSE for an explicit green-light** — the one human gate; never
   self-approved, never skipped.
3. On green-light: write the **plan** at `plans/YYYY-MM-DD-<feature>.md`, then execute it **fully
   autonomously** — fresh subagent per task, review between tasks, no further approval pauses.
4. Finish with **docs + tests** and the repo's full quality gate green (its configured typecheck + test
   [+ lint / build]), then **ship**. Stop only for a CEO-reserved decision, a destructive/irreversible/
   outward action, or decomposition into sub-specs.

Specs go in `specs/`, plans in `plans/` (never `superpowers/`). Full procedure:
`~/code/me/org/sop/12-build-a-codebase.md` (or `firm seed lipost`). Inherited, not copied — the apex
owns it; this repo may *tighten* but never relax it.
