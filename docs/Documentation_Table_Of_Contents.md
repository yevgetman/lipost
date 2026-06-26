# Documentation Table of Contents

This is the entry point for the lipost documentation set. Use it to orient yourself before reading any
individual doc.

These docs describe **the current state of the codebase** (the single-file CLI at `bin/lipost`). They are a
progressively-disclosed corpus (SOP-13): a lean root router (`CLAUDE.md` / `AGENTS.md`) points here; this
index points at focused docs you open on demand. The README stays the human-facing walkthrough; these docs
are the agent-and-maintainer view.

> Documentation is treated like code — updated and pruned for accuracy in the same commit as the code it
> describes. See [How to work with the docs](How_To_Work_With_Docs.md).

---

## How to read these docs

The directory structure is **progressive**, ordered most-general to most-specific. If you only have five
minutes, read `01-overview/`. If you have fifteen, add `02-architecture/single-file-design.md`. Look up a
specific command in `03-cli-reference/`.

---

## 01 — Overview

What lipost is and the model behind it.

- [What is lipost](01-overview/what-is-lipost.md) — the one-paragraph definition, what ships, what it is not, hard dependencies
- [The three layers](01-overview/the-three-layers.md) — primitive / article / bot — each optional, and how they share state

## 02 — Architecture

How the tool is built and why.

- [Single-file design](02-architecture/single-file-design.md) — one stdlib-only Python file, argparse dispatch, the hidden `_cron` entry points, exit conventions
- [Runtime data layout](02-architecture/runtime-data-layout.md) — where state lives outside the repo (`~/.config/lipost`, `~/.local/share/lipost`), permissions, legacy-path migration
- [LinkedIn API & auth](02-architecture/linkedin-api-and-auth.md) — the OAuth flow, scopes, token lifetime, the monthly `LinkedIn-Version` pin, and the REST endpoints used
- [The bot & launchd](02-architecture/the-bot-and-launchd.md) — the draft queue, the three phases (generate / review / post), the two launchd jobs, the jitter trick, and the safety gates

## 03 — CLI reference

The canonical command surface.

- [Command reference](03-cli-reference/command-reference.md) — every command and flag, grouped by layer
- [Bot config reference](03-cli-reference/bot-config-reference.md) — every `bot.json` key, common config recipes, and the kill switches

---

## Quick navigation

| If you're trying to … | Start here |
|------------------------|-----------|
| Understand what lipost is | [What is lipost](01-overview/what-is-lipost.md) |
| Decide which layer you need | [The three layers](01-overview/the-three-layers.md) |
| Find where state is stored on disk | [Runtime data layout](02-architecture/runtime-data-layout.md) |
| Fix an HTTP 426 / `NONEXISTENT_VERSION` error | [LinkedIn API & auth](02-architecture/linkedin-api-and-auth.md) |
| Understand how the autoposter is scheduled | [The bot & launchd](02-architecture/the-bot-and-launchd.md) |
| Look up a command or flag | [Command reference](03-cli-reference/command-reference.md) |
| Tune the bot's schedule or turn it off | [Bot config reference](03-cli-reference/bot-config-reference.md) |

---

## Cross-references

- [`/CLAUDE.md`](../CLAUDE.md) / [`/AGENTS.md`](../AGENTS.md) — repo-root agent router (read first, then this TOC)
- [`/README.md`](../README.md) — the full human-facing walkthrough and first-time LinkedIn-app setup
- [How to work with the docs](How_To_Work_With_Docs.md) — the procedure for changing this set
