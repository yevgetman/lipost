# lipost

A small, dependency-free Python CLI for posting to your **personal LinkedIn feed** from the terminal — plus two optional layers on top.

- **Primitive** — `lipost {init,auth,post,edit,delete,whoami}`. Direct LinkedIn API operations, OAuth, image upload. This is what most people will use, and it works on its own.
- **Article skill** — `lipost article <url>`. Pipe an article URL through Claude Code, review the draft, and publish (or queue).
- **Bot / queue** — `lipost {drafts,bot} ...`. Stage images, generate captioned drafts via Claude, review them in a TUI, and have a launchd-driven cron post one per day at a randomized human-ish time.

Each layer is optional. The only hard dependency is Python 3.9+ (stdlib only — no `pip install`). The article skill and bot also need [Claude Code](https://docs.claude.com/en/docs/claude-code) on your PATH. The bot requires macOS (uses `launchd`).

> **⚠️ Heads up: `LinkedIn-Version` may need bumping.** LinkedIn pins every API call to a monthly version (`202604` at time of writing) and rotates them on a ~12-month deprecation window. If image upload, post, edit, or delete ever fails with **HTTP 426 / `NONEXISTENT_VERSION`**, edit `LINKEDIN_API_VERSION` near the top of `bin/lipost` to a current month. Available versions: [LinkedIn API versioning docs](https://learn.microsoft.com/en-us/linkedin/marketing/versioning).

---

## Quick start

```bash
git clone https://github.com/yevgetman/lipost.git
cd lipost
./install.sh                                 # symlinks bin/lipost onto your PATH
lipost init                                  # OAuth credentials + first-time setup
lipost auth                                  # browser OAuth (one redirect)
lipost post "Hello LinkedIn!"
```

That's the whole happy path for the primitive layer. The article skill and bot are documented further down.

---

## What's where

```
lipost/
├── bin/lipost              # the CLI (single file, stdlib only)
├── share/
│   ├── prompt.example.md   # image-mode prompt example with TEMPLATE marker
│   └── style.md            # baked-in formatting & punctuation layer
├── install.sh              # symlinks bin/lipost into ~/.local/bin (or similar)
├── config.example.json     # auth credentials template
└── README.md
```

**Runtime data lives outside the repo:**

| Path | Purpose |
| --- | --- |
| `~/.config/lipost/auth.json`     | LinkedIn `client_id` / `client_secret` (chmod 600) |
| `~/.config/lipost/token.json`    | OAuth access token + member URN (chmod 600) |
| `~/.config/lipost/bot.json`      | Bot settings (chmod 600) |
| `~/.config/lipost/state.json`    | Bot state — `last_run_at`, `paused` |
| `~/.config/lipost/posts.jsonl`   | Append-only post history |
| `~/.config/lipost/prompt.md`     | Live persona prompt (used by article + image generation) |
| `~/.config/lipost/user_style.md` | Optional user additions to the style layer |
| `~/.config/lipost/launchd/`      | Generated plists |
| `~/.local/share/lipost/drafts/`  | Draft queue (one dir per draft) |
| `~/.local/share/lipost/images/`  | Image staging — `pending/` and `skipped/` |
| `~/Library/Logs/lipost.log`      | Bot logs and lipost stdout/stderr |

`lipost init` and `lipost bot init` migrate from the legacy `~/.config/linkedin-cli/`, `~/.config/lipost-bot/`, and `~/code/lipost-bot/{drafts,images,prompt.md}` paths if they're found.

---

## Layer 1 — primitives

### One-time LinkedIn app setup

Before `lipost init` you need credentials from a LinkedIn developer app. ~5 minutes; LinkedIn doesn't provide test credentials, so every developer needs their own app.

1. Go to <https://developer.linkedin.com/> → **Create app**. Required fields:
   - **App name** — anything (only you see it on the consent screen).
   - **LinkedIn Page** — required even for personal use. **It does not affect where posts go.** Posts always land on the personal feed of whoever authenticates. If you don't admin a page, click *Create a new LinkedIn Page*, pick "Small business", and make a throwaway page (e.g. your name + " Dev"). You'll never use it again.
   - **Privacy policy URL** — optional. Leave blank or paste any URL.
   - **App logo** — required, square ≥100px. Anything works.
2. **Auth tab** → *Authorized redirect URLs* → add `http://localhost:8765/callback`.
3. **Products tab** → request access (auto-approved within seconds for personal apps):
   - **Sign In with LinkedIn using OpenID Connect** — gives the CLI your member ID at auth time.
   - **Share on LinkedIn** — grants the `w_member_social` scope needed to post.

   You don't need *Marketing Developer Platform* — that's for posting on behalf of *other* users, heavily gated.
4. **Auth tab** → copy **Client ID** and **Client Secret**. `lipost init` will prompt for these.

### What `lipost init` does

- Migrates legacy paths (`~/.config/linkedin-cli/`) into `~/.config/lipost/` if found.
- Prompts for Client ID / Client Secret, writes them to `~/.config/lipost/auth.json` (chmod 600).
- Offers to symlink `bin/lipost` into a directory on your `PATH`.
- Warns if the chosen directory isn't on `PATH` and prints the line to add to your shell rc.

If you'd rather skip the interactive setup, set environment variables (they take precedence over the config file):

```bash
export LINKEDIN_CLIENT_ID=xxx
export LINKEDIN_CLIENT_SECRET=yyy
```

Re-run `lipost init` any time to update credentials or relink the binary.

### Usage

```bash
lipost auth                                            # one-time browser OAuth
lipost whoami                                          # show authenticated person URN

# Text posts
lipost post "Hello LinkedIn!"
lipost post -                                          # read body from stdin
lipost post --dry-run "test"                           # show the JSON without sending

# Image posts (with optional caption + alt text)
lipost post --image photo.jpg "Caption goes here"
lipost post --image photo.png --alt "A red bicycle" "Out for a ride"
lipost post --image photo.jpg                         # image with no caption

# Edit (commentary text only — image/visibility are locked after publish)
lipost edit urn:li:share:1234567890 "Updated text here"

# Delete
lipost delete urn:li:share:1234567890
```

### Posting to the queue (no daemon required)

`--queue` enqueues a text-only draft instead of posting immediately. Useful when you want to write something but defer publishing — and you don't necessarily need the bot daemon installed to use it.

```bash
lipost post --queue "draft I'll let sit overnight"          # status=approved
lipost post --queue-pending "needs another pass"            # status=pending_approval
```

The draft lands in `~/.local/share/lipost/drafts/`. Review with `lipost drafts review`, list with `lipost drafts`, post the next approved one with `lipost drafts run`. If you want this happening on a schedule, see the bot section.

`--queue` is text-only. For an image post, use the image-staging flow under the bot section.

### Testing without spamming your feed

LinkedIn doesn't offer a sandbox / test environment for the Posts API. Two safe approaches:

1. **Dry run.** `--dry-run` prints the exact JSON that would be sent, without hitting LinkedIn. No rate-limit cost, no post created.
   ```bash
   lipost post --dry-run "this is a test"
   ```
2. **Post then delete.** When `post` succeeds, the CLI prints the URN and a ready-to-paste delete command:
   ```bash
   $ lipost post "test from CLI"
   posted: urn:li:share:7185023485712384000
   url:    https://www.linkedin.com/feed/update/urn:li:share:7185023485712384000/
   to delete: lipost delete urn:li:share:7185023485712384000

   $ lipost delete urn:li:share:7185023485712384000
   deleted: urn:li:share:7185023485712384000
   ```
   Network distribution isn't instant; deleting within seconds makes it very unlikely anyone saw it.

### Token lifetime

LinkedIn member tokens last ~60 days. When yours expires, re-run `lipost auth`.

---

## Layer 2 — `lipost article <url>`

Turn an article URL into a LinkedIn post. The flow:

1. You provide a URL (or get prompted).
2. The script invokes `claude -p` (Opus 4.7, `--dangerously-skip-permissions`) with your persona prompt + a fixed article-handling wrapper.
3. Claude fetches the article (via the WebFetch tool) and outputs a JSON-shaped draft caption.
4. The draft shows in the terminal. You pick: `[a]pprove`, `[e]dit`, `[r]egenerate`, `[q]ueue`, `[c]ancel`.
5. On approve → `lipost post` publishes. On queue → enters the draft queue (see Layer 3).

```bash
lipost article                                    # prompts for URL
lipost article https://blog.example.com/post      # generate + review + post
lipost article --dry-run https://...              # everything except the actual publish
lipost article --queue https://...                # at [q] → enqueue as approved
lipost article --queue-pending https://...        # at [q] → enqueue as pending_approval
```

### Requirements

- `claude` (Claude Code CLI) on `PATH`, logged in, with access to Opus 4.7.
- `lipost init` + `lipost auth` already run.
- A persona prompt at `~/.config/lipost/prompt.md` (or set `LIPOST_PROMPT=/path/to/prompt.md`).

### What goes in the persona prompt

`~/.config/lipost/prompt.md` is your **persona/voice/audience block**: who is writing, what they sound like, who they're writing for, banned phrases, length budget — anything stylistic that's about *what to say*. The article wrapper handles the article-specific instructions (fetch the URL, react to one specific thing, end with the URL line, etc.) and the JSON output schema, so `prompt.md` itself only needs voice rules.

The same persona prompt is also consumed by the bot's image-driven generation. If your prompt also contains `{{IMAGE_PATH}}` and image-mode instructions (the example does), the article wrapper tells Claude to ignore those bits — so one file works for both modes.

If you want **separate** prompts for article vs image mode, point at a different file with `LIPOST_PROMPT` (article only) or maintain `~/.config/lipost/prompt.md` for image mode and use the env var to override for article runs.

### What goes in `style.md`

`share/style.md` ships with the repo. Mechanical formatting rules: punctuation, capitalization, paragraph breaks, character set, emoji policy, length caps. **Not** voice or content rules. View it with `lipost style --baked`.

For your own additions, edit `~/.config/lipost/user_style.md` via `lipost style`. Image generation auto-appends both layers to the prompt. (Article mode uses only the baked layer for now.)

---

## Layer 3 — drafts queue + bot daemon

A launchd-driven autonomous LinkedIn poster with a human-in-the-loop approval queue.

You batch-generate captioned drafts from staged images, review them in a TUI, approve the ones you like — and the bot posts the approved queue, one per day, at a randomized human-ish time.

- macOS only (uses `launchd`).
- Phases are independently triggered:
  1. **Generate** (`lipost drafts generate`, manual; or auto-cron). Drains `~/.local/share/lipost/images/pending/`. For each image, runs Claude with your `prompt.md` + the style layer. Output is a `(caption, alt)` JSON blob saved as a `pending_approval` draft.
  2. **Review** (`lipost drafts review`, manual). Walks pending drafts: image path + caption + alt in terminal, then `[a]pprove / [r]eject / [e]dit / [g]enerate-again / [s]kip / [q]uit`.
  3. **Post** (launchd, automatic; or `lipost drafts run`, manual). When launchd fires at the daily `baseline_hour`, the wrapper sleeps a random `0…N` seconds (jitter), then picks the **oldest approved draft** and posts it via `lipost post`.

A min-hours-between-runs guard (default 20h) prevents accidental double-posting. A master `active` flag (default `false` after `bot init`) gates everything.

**Optional auto-generate cron**. A second launchd job (`local.lipost.generate`) periodically scans `images/pending/` and runs Phase 1 on anything new — gated by its own `generate_active` flag and configurable interval (default every 8h).

### Install

```bash
lipost bot init
```

`bot init` is interactive. It will:

1. Run a dependency preflight (refuses to continue if `claude` or LinkedIn auth is missing; pass `--force` to override).
2. Migrate any legacy state from a previous `lipost-bot` install (interactive prompts).
3. Prompt for `baseline_hour`, `jitter_max_secs`, `min_hours_between_runs`, `permission_mode`. Press enter to accept defaults.
4. Write `~/.config/lipost/bot.json` (`active=false` by default).
5. Create `~/.local/share/lipost/{drafts,images/pending,images/skipped}/`.
6. Seed `~/.config/lipost/prompt.md` from `share/prompt.example.md` if it doesn't already exist (TEMPLATE marker on line 1; bot stays inert).
7. Symlink `bin/lipost` into `~/.local/bin/`.
8. Generate two plists, symlink into `~/Library/LaunchAgents/`, load them. Both inert until you flip `active=true` and/or `generate_active=true`.

After this, the schedule is **live but inert**. Two independent gates keep it from posting:

1. **`active=false`** in `bot.json` — master arm switch.
2. **The TEMPLATE marker** on line 1 of `prompt.md` — until you delete it, `drafts generate` refuses to run.

```bash
lipost bot status
```

You should see `active: False ← inert`, `deps: OK`, `launchd: loaded`, `prompt: template`, and `drafts: approved=0, pending=0, …`.

### Configure

All settings live in `~/.config/lipost/bot.json`. Show with `lipost bot config`. Update with `lipost bot config <key> <value>` (validated and cast to the right type). Editing `baseline_hour` or `generate_interval_hours` automatically regenerates the plist and reloads launchd.

| Key | Default | What it controls |
| --- | --- | --- |
| `active` | `false` | Master arm switch for the **post** cron. `lipost drafts run` ignores this; `_cron` honors it. |
| `generate_active` | `false` | Master arm switch for the **generate** cron (auto-drains `images/pending/`). Manual `drafts generate` ignores it. |
| `generate_interval_hours` | `8` | How often the generate cron fires. Min `1`. |
| `baseline_hour` | `9` | Hour (0–23) at which launchd fires, before jitter. |
| `jitter_max_secs` | `43200` (12h) | Max seconds the wrapper sleeps after baseline before posting. Set to `0` for a deterministic fire at exactly `baseline_hour:00`. |
| `min_hours_between_runs` | `20` | If the previous run started less than this many hours ago, `_cron` skips. |
| `permission_mode` | `bypassPermissions` | Passed to `claude -p` during generate as `--permission-mode`. |
| `claude_model` | `claude-opus-4-7` | Passed to `claude -p` as `--model`. Default is Opus 4.7 because image interpretation benefits from the strongest model. |

#### Common config recipes

```bash
# Post strictly between 11:00 and 17:00 each day
lipost bot config baseline_hour 11
lipost bot config jitter_max_secs 21600

# Post at exactly 09:00 every day (no jitter)
lipost bot config jitter_max_secs 0

# Use Sonnet during generate (faster, cheaper, weaker at images)
lipost bot config claude_model claude-sonnet-4-6

# Turn on auto-generate cron (drains images/pending/ every 8h)
lipost bot config generate_active true

# Run the auto-generate cron every 4h
lipost bot config generate_interval_hours 4
```

### Schedule mechanics

`launchd` doesn't have native jitter. The trick: `launchd` fires at `baseline_hour` daily, and the wrapper sleeps a uniform random `0…jitter_max_secs` before posting. So the actual post drifts inside a window each day. `lipost bot next` prints the next window.

### Write the prompt

```bash
lipost prompt          # opens ~/.config/lipost/prompt.md in $EDITOR
```

The shipped `share/prompt.example.md` has a working starter. Two important things on it:

1. **Line 1 is a `<!-- TEMPLATE: … -->` marker.** While that line is present, `drafts generate` refuses to run. Delete it once you've customized the body.
2. **The body uses image mode** (it includes `{{IMAGE_PATH}}`). The wrapper substitutes that with an absolute path at run time.

#### What the prompt must produce

The wrapper parses Claude's stdout for a single JSON object. **The prompt must instruct Claude to output JSON only, no preamble, no code fence.** Two shapes are accepted:

```json
{"caption": "<post body>", "alt": "<one-line factual description>"}
```

```json
{"skip": true, "reason": "<short explanation>"}
```

If parsing fails (no valid JSON), `drafts generate` logs the failure for that image and leaves it in `pending/` for retry.

#### What every prompt should include

- The `{{IMAGE_PATH}}` placeholder (substituted at run time).
- An instruction to **read the image** (Claude's Read tool accepts JPEG/PNG/GIF; for GIFs it sees a representative frame).
- A `SKIP` clause: tell Claude what conditions warrant `{"skip": true, ...}` — image off-domain, ambiguous, repetitive.
- **Voice and content constraints**: tone, topic, length, what NOT to write about, banned phrases, opening/closing rules.
- An explicit instruction to **output ONLY the JSON** — no explanation, no code fence.

#### What does NOT belong in the prompt

The style layer (`share/style.md` + `~/.config/lipost/user_style.md`) is auto-appended to every generate-time prompt. It already covers all the **mechanical formatting rules**. Don't duplicate them in `prompt.md` — and avoid contradicting them, since the style layer is appended after the prompt body and Claude treats it as authoritative for mechanics.

### Stage, generate, review, arm

```bash
# 1. Stage one or more images
cp ~/Pictures/diagram.png ~/.local/share/lipost/images/pending/
# Or open the dir in Finder and drag them in:
lipost images --open

# 2. Confirm they're picked up
lipost images

# 3. Edit the prompt — and DELETE the TEMPLATE marker on line 1 when ready
lipost prompt

# 3b. (Optional) Add personal formatting tweaks
lipost style              # opens user_style.md in $EDITOR
lipost style --show       # preview the combined layer that gets injected

# 4. Drain the pending dir into drafts (this calls Claude once per image)
lipost drafts generate

# 5. Review each draft in the TUI
lipost drafts review
# Press a/r/e/g/s/q for each draft.

# 6. Verify state — `drafts: approved=N` should be > 0
lipost bot status
lipost drafts --status approved

# 7. Sanity-check what the bot would do at fire time
lipost drafts run --no-fire

# 8. Test-post the next approved draft NOW
lipost drafts run
lipost posts --open       # see it on LinkedIn
lipost delete <urn>       # if you want it gone

# 9. Arm the post schedule
lipost bot config active true
lipost bot status         # active: True

# 10. (Optional, fully unattended) Arm the auto-generate cron too.
lipost bot config generate_active true
```

After step 9, the launch agent fires daily at `baseline_hour`, sleeps the jitter, and pops the next approved draft. After step 10, you no longer need to run `drafts generate` manually — the cron drains `images/pending/` on its 8h interval.

### Day-to-day

`lipost cheatsheet` prints a curated short list. The full surface:

```bash
lipost bot status              # everything in one screen
lipost drafts                  # queue grouped by status
lipost drafts --status approved
lipost images                  # what's staged
lipost images --open           # open pending dir in Finder
lipost drafts generate         # whenever you've staged new images
lipost drafts review           # whenever there are pending drafts
lipost prompt                  # edit prompt.md (voice, content, JSON shape)
lipost style                   # edit user_style.md (your formatting tweaks)
lipost style --show            # preview the full style layer
lipost bot pause / resume      # transient pause without unloading launchd
lipost bot stop / start        # off / on the schedule
lipost drafts run --no-fire    # inspect the next post without publishing
lipost drafts run              # post the next approved draft now
lipost bot next                # next scheduled fire window
lipost bot logs -f             # tail live activity
lipost posts                   # post history (URN + image)
lipost posts --open            # open the most recent post on LinkedIn
```

### Kill switches (in order of severity)

| You want to… | Run |
| --- | --- |
| Disarm the post schedule (durable) | `lipost bot config active false` |
| Disarm the auto-generate cron | `lipost bot config generate_active false` |
| Pause transiently for a few days | `lipost bot pause` |
| Drain the approved queue without posting | Hand-edit `drafts/<slug>/meta.json` and change each `"status": "approved"` to `"rejected"`. The cron trusts what's on disk. Or `rm -rf drafts/<slug>` to remove entirely. |
| Take the bot off the schedule completely | `lipost bot stop` |
| Remove the install but keep config + drafts + history | `lipost bot uninstall` |
| Nuclear: remove everything | `lipost bot uninstall && rm -rf ~/.config/lipost ~/.local/share/lipost ~/Library/Logs/lipost.log` |

`active` vs `paused` vs `stop`: all three prevent posts at different layers. `active` is the durable master switch in config. `paused` is a transient flag in state. `stop` unloads the launch agent entirely.

### Draft `meta.json` schema

```json
{
  "slug": "20260430T093412_a1b2c3",
  "status": "pending_approval",
  "caption": "...",
  "alt_text": "...",
  "image_filename": "image.png",
  "source_filename": "diagram.png",
  "source_url": null,
  "created_at": "...",
  "approved_at": null,
  "rejected_at": null,
  "posted_at": null,
  "urn": null,
  "model": "claude-opus-4-7"
}
```

You can edit `meta.json` directly — bulk-approve, fix typos, change a draft's status. The cron trusts what's on disk.

### Safety notes

- **`bypassPermissions` is wide.** `drafts generate` runs Claude with `--permission-mode bypassPermissions` so it doesn't hang on prompts. Inside the working directory Claude can read/write files and run shell commands without confirmation. Don't keep secrets there.
- **Human approval is the safety boundary.** Nothing posts until you `review` and approve. Pre-fire, you also still have `lipost delete` if you change your mind after a post lands.
- **The LinkedIn token expires.** Member tokens last ~60 days. When yours expires, `lipost post` will 401 and `_cron` will leave the draft as `approved` for retry. Re-run `lipost auth`.
- **No retries inside a run.** `_cron` records `last_run_at` *before* posting. If the post fails or no URN comes back, the draft stays `approved` for the next scheduled run — but the gap guard means the next attempt is ~24h later.
- **5-minute hard timeout on the post.** If LinkedIn hangs, `_cron` aborts and the draft stays `approved`.
- **10-minute timeout on each Claude call** during generate. A timeout leaves the source image in `pending/` for retry.
- **Prompt injection via images.** Claude reads images you stage. A maliciously crafted image with embedded text could try to override your prompt. Stage images you trust.

---

## Migration from the old separate repos

This repo replaces three previously-separate tools:

- `lipost` (this repo, original layout) → now in `bin/lipost`
- `lipost-article` ([yevgetman/lipost-article](https://github.com/yevgetman/lipost-article)) → `lipost article <url>`
- `lipost-bot` ([yevgetman/lipost-bot](https://github.com/yevgetman/lipost-bot)) → `lipost {drafts,bot} ...`

If you have any of the old installs:

1. `git pull` (or re-clone) this repo to get the new layout.
2. Run `./install.sh` to symlink the new `bin/lipost` onto your PATH (replacing the old single-file `lipost` script).
3. Run `lipost init` — it will detect `~/.config/linkedin-cli/` and offer to migrate it into `~/.config/lipost/`.
4. If you used `lipost-bot`, run `lipost bot init` — it will:
   - Unload the old `local.lipost-bot.*` launchd jobs.
   - Migrate `~/.config/lipost-bot/` → `~/.config/lipost/`.
   - Migrate `~/code/lipost-bot/{drafts,images,prompt.md,user_style.md}` → `~/.local/share/lipost/` and `~/.config/lipost/`.
   - Install the new `local.lipost.{post,generate}` launchd jobs.

The migrations are interactive (one prompt per file/dir, default Y) and idempotent. The legacy paths are also read as read-only fallbacks before re-init, so existing installs keep working until you migrate.

---

## License

MIT — see [LICENSE](LICENSE).
