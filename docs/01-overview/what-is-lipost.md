# What is lipost

lipost is a small, **dependency-free Python CLI** for posting to your **personal LinkedIn feed** from the
terminal — plus two optional layers on top of that primitive.

The phrase is load-bearing:

- **CLI** — a command-line tool you symlink onto your `PATH` (`./install.sh`) and invoke per command. Not a
  server, not a hosted service.
- **dependency-free** — the only hard requirement is **Python 3.9+ (stdlib only)**. No `pip install`. The
  whole tool is a single file, `bin/lipost`. (The article skill and bot add optional external requirements —
  see below.)
- **personal LinkedIn feed** — posts always land on the personal feed of whoever authenticates. lipost uses
  the `w_member_social` scope; it does not post on behalf of other users or to company pages.

---

## What ships

The repo is deliberately tiny:

| Path | What it is |
| --- | --- |
| `bin/lipost` | The entire CLI — one Python file, stdlib only |
| `share/style.md` | The baked-in mechanical formatting layer (punctuation, length caps, emoji policy) |
| `share/prompt.example.md` | A starter persona prompt for image-mode generation (ships with a `TEMPLATE` marker that keeps the bot inert) |
| `install.sh` | Symlinks `bin/lipost` onto your `PATH` |
| `config.example.json` | Auth-credentials template |
| `README.md` | The full human walkthrough |

All **runtime state lives outside the repo**, under `~/.config/lipost/` and `~/.local/share/lipost/`. See
[Runtime data layout](../02-architecture/runtime-data-layout.md).

---

## The three layers (each optional)

1. **Primitive** — `lipost {init,auth,whoami,post,edit,delete}`. Direct LinkedIn API operations, OAuth,
   image upload. This is what most people use, and it works on its own.
2. **Article skill** — `lipost article <url>`. Pipe an article URL through Claude Code, optionally generate
   an image with OpenAI, review the draft, and publish or queue it.
3. **Bot / queue** — `lipost {drafts,bot} …`. Stage images, generate captioned drafts via Claude, review
   them in a TUI, and let a launchd cron post one approved draft per day at a randomized human-ish time.

Each layer is opt-in and adds its own requirements. See [The three layers](the-three-layers.md).

---

## What lipost is not

- **Not a scheduler service.** The bot is a thin wrapper over macOS `launchd` running on your machine — no
  hosted backend, no account.
- **Not multi-account or company-page posting.** One authenticated member, their personal feed.
- **Not a content generator on its own.** Layers 2 and 3 delegate the writing to **Claude Code** running
  locally; lipost supplies the prompt scaffolding, the review gate, and the LinkedIn plumbing.
- **Not cross-platform for the bot.** The bot requires macOS (`launchd`). The primitive and article layers
  are portable wherever Python 3.9+ runs.

---

## Dependencies by layer

| Layer | Hard requirement | Optional |
| --- | --- | --- |
| Primitive | Python 3.9+, a LinkedIn developer app (Client ID/Secret) | — |
| Article | Above + `claude` (Claude Code) on `PATH` with Opus access | `OPENAI_API_KEY` for `--with-image` |
| Bot | Above + **macOS** (`launchd`) | `generate_active` auto-generate cron |

---

## Read next

- [The three layers](the-three-layers.md) — how the primitive, article, and bot layers relate and share state
- [Single-file design](../02-architecture/single-file-design.md) — how the one-file CLI is structured
- [Command reference](../03-cli-reference/command-reference.md) — the full command surface
