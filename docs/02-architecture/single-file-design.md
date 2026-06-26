# Single-file design

The entire CLI is one Python file, `bin/lipost` (~2,900 lines), using **only the standard library**. There is
no package, no build step, and nothing to `pip install`. `install.sh` symlinks this file onto your `PATH`.

This is a deliberate constraint: the tool must run on any machine with Python 3.9+ and survive being copied
around as a single script.

---

## Structure of the file

The file reads top-to-bottom as:

1. **Module docstring** — the three-layer summary.
2. **stdlib imports only** — `argparse`, `json`, `urllib`, `subprocess`, `http.server`, `webbrowser`,
   `pathlib`, etc. (No third-party imports anywhere.)
3. **Paths & constants** — `CONFIG_DIR`, `DATA_DIR`, the per-file paths, the OAuth `SCOPES`/`REDIRECT_URI`,
   and `LINKEDIN_API_VERSION`. `REPO_DIR` is derived from the script's own resolved path so `share/` is
   found regardless of where the symlink lives. See [Runtime data layout](runtime-data-layout.md) and
   [LinkedIn API & auth](linkedin-api-and-auth.md).
4. **Helpers** — including `die(msg, code=1)` (print to stderr, `sys.exit`) and small HTTP/JSON wrappers over
   `urllib`.
5. **Command functions** — one `cmd_*` per command (`cmd_post`, `cmd_article`, `cmd_bot_status`, …).
6. **Argument parsing** — a single `argparse` parser with subparsers, built at the bottom of the file. Each
   subparser binds a `func=cmd_*` via `set_defaults`.

---

## Command dispatch

`argparse` subparsers map the command surface:

- Top-level commands: `init`, `auth`, `whoami`, `post`, `edit`, `delete`, `article`, `posts`, `images`,
  `prompt`, `style`, `cheatsheet`.
- Two commands nest a second level of subparsers:
  - `drafts {list,add,review,generate,run}` — `list` is the default when no action is given.
  - `bot {init,status,config,pause,resume,start,stop,next,logs,uninstall}`.

Every leaf subparser sets `func` to its `cmd_*` handler; the dispatcher calls `args.func(args)`.

See [Command reference](../03-cli-reference/command-reference.md) for the full surface.

---

## Hidden `_cron` entry points

The launchd plists do **not** call the user-facing commands. They call hidden internal entry points
(`cmd_cron` / `cmd_cron_generate`, dispatched outside the normal subparser tree) so the schedule logic is
separate from the interactive surface. These are what enforce the bot's gates (the `active` flag, the
min-hours guard, the jitter sleep). See [The bot & launchd](the-bot-and-launchd.md).

---

## Conventions

- **Errors exit non-zero via `die()`.** User-facing failures print a message to stderr and `sys.exit(1)`.
  Interrupted interactive flows exit `130` (SIGINT convention).
- **No mutation of shared global state** beyond reading/writing the on-disk JSON files, which are the single
  source of truth (the cron "trusts what's on disk").
- **External processes** (`claude`, `wrangler`-style tools, `$EDITOR`, `launchctl`) are shelled out via
  `subprocess` with explicit timeouts where a hang would be harmful (5-minute cap on a post, 10-minute cap on
  each Claude generate call).

---

## Read next

- [Runtime data layout](runtime-data-layout.md) — the on-disk files the commands read and write
- [LinkedIn API & auth](linkedin-api-and-auth.md) — the network layer
- [The bot & launchd](the-bot-and-launchd.md) — the `_cron` entry points and scheduling
