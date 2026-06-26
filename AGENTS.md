# lipost — the `lipost` node of The Firm

> `CLAUDE.md` is mirrored at `AGENTS.md` — edit both.

A small, dependency-free Python CLI for posting to your personal LinkedIn feed from the terminal, plus two
optional layers: an article→post skill (`lipost article <url>`) and a launchd-driven autoposter with a
human-approval draft queue (`lipost {drafts,bot} …`).

## Documentation (progressive disclosure — SOP-13)

This is a thin router. The docs are progressively disclosed: start at the master index, then descend on
demand — never read the whole corpus to find one fact.

| Read this | When you want to … |
| --- | --- |
| [docs/Documentation_Table_Of_Contents.md](docs/Documentation_Table_Of_Contents.md) | Orient — the master index of every doc |
| [docs/01-overview/what-is-lipost.md](docs/01-overview/what-is-lipost.md) | Understand what lipost is + the three-layer model |
| [docs/02-architecture/single-file-design.md](docs/02-architecture/single-file-design.md) | See how the single-file CLI, runtime data, auth, and the bot are built |
| [docs/03-cli-reference/command-reference.md](docs/03-cli-reference/command-reference.md) | Look up a command, flag, or `bot.json` config key |
| [README.md](README.md) | The full human-facing walkthrough + first-time setup |
| [docs/How_To_Work_With_Docs.md](docs/How_To_Work_With_Docs.md) | Add, edit, move, or delete a doc (read before touching `docs/`) |

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
