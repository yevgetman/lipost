# The three layers

lipost is one binary that exposes three layers of capability. Each is **optional** and adds its own
requirements, but they share a common foundation (auth + the `post` primitive) and a common queue.

```
Layer 1  Primitive   init · auth · whoami · post · edit · delete
Layer 2  Article      article <url>           → (review) → post | queue
Layer 3  Bot / queue  drafts · bot            → (review) → launchd posts 1/day
                       images · prompt · style · posts · cheatsheet  (shared tooling)
```

---

## Layer 1 — primitives

Direct LinkedIn API operations. After a one-time LinkedIn developer-app setup, `lipost init` stores your
credentials, `lipost auth` runs the browser OAuth, and `lipost post` publishes text or image posts. `edit`
changes a post's commentary text (image and visibility are locked after publish); `delete` removes a post by
URN. This layer stands entirely on its own and needs nothing beyond Python and a LinkedIn app.

The `post` command is also the **shared publish primitive** the other two layers call once a draft is
approved.

## Layer 2 — the article skill

`lipost article <url>` turns an article into a post:

1. lipost invokes `claude -p` (Opus, `--dangerously-skip-permissions`) with your persona prompt plus a fixed
   article-handling wrapper.
2. Claude fetches the article and returns a JSON-shaped draft caption.
3. The draft shows in the terminal; you pick `[a]pprove`, `[e]dit`, `[r]egenerate`, `[q]ueue`, or `[c]ancel`.
4. Approve → `lipost post` publishes. Queue → the draft enters the same queue Layer 3 uses.

Adds **Claude Code** as a requirement; `--with-image` additionally needs `OPENAI_API_KEY`.

## Layer 3 — the drafts queue + bot daemon

A launchd-driven autoposter with a **human-in-the-loop approval queue**. You batch-generate captioned drafts
from staged images, review them, approve the good ones, and the bot posts the approved queue one per day at a
randomized time. Three phases run independently:

1. **Generate** — drains `~/.local/share/lipost/images/pending/`; one Claude call per image produces a
   `(caption, alt)` draft.
2. **Review** — a TUI walks pending drafts (`a/r/e/g/s/q`).
3. **Post** — launchd fires daily, sleeps a random jitter, then posts the oldest approved draft.

Adds **macOS** (`launchd`) as a requirement. See [The bot & launchd](../02-architecture/the-bot-and-launchd.md).

---

## What the layers share

- **The publish primitive.** Layers 2 and 3 both end by calling Layer 1's `post`.
- **The draft queue.** `lipost post --queue`, `lipost article --queue`, and the bot's generate phase all
  write to `~/.local/share/lipost/drafts/`. You can use the queue **without installing the bot daemon** —
  `--queue` enqueues, `lipost drafts review` approves, `lipost drafts run` posts the next approved draft
  manually.
- **The persona prompt.** `~/.config/lipost/prompt.md` (your voice/audience block) feeds both the article
  skill and the bot's image generation.
- **The style layer.** `share/style.md` (baked, mechanical formatting) plus optional
  `~/.config/lipost/user_style.md` is auto-appended at generate time.

---

## Read next

- [What is lipost](what-is-lipost.md) — the definition and what ships
- [The bot & launchd](../02-architecture/the-bot-and-launchd.md) — the Layer 3 mechanics in detail
- [Command reference](../03-cli-reference/command-reference.md) — every command in each layer
