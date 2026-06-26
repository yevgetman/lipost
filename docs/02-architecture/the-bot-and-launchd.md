# The bot & launchd

Layer 3 is a **launchd-driven autoposter with a human-in-the-loop approval queue**. This doc explains the
phases, the two launchd jobs, the jitter trick, and the safety gates. macOS only (it uses `launchd`).

For the command surface see [Command reference](../03-cli-reference/command-reference.md); for every config
key see [Bot config reference](../03-cli-reference/bot-config-reference.md).

---

## The three phases (independently triggered)

1. **Generate** (`lipost drafts generate`, manual; or the auto-generate cron). Drains
   `~/.local/share/lipost/images/pending/`. For each image, runs Claude with your `prompt.md` + the style
   layer. Output is a `(caption, alt)` JSON blob saved as a `pending_approval` draft. A parse failure leaves
   the image in `pending/` for retry. Each Claude call has a 10-minute timeout.
2. **Review** (`lipost drafts review`, manual). A terminal TUI walks pending drafts — image path + caption +
   alt — and you press `[a]pprove / [r]eject / [e]dit / [g]enerate-again / [s]kip / [q]uit`.
3. **Post** (launchd, automatic; or `lipost drafts run`, manual). At the daily fire time the wrapper sleeps a
   random jitter, then picks the **oldest approved draft** and posts it via the `post` primitive. A 5-minute
   hard timeout guards a hung request.

**Human approval is the safety boundary** — nothing posts until you review and approve, and `lipost delete`
is still available after a post lands.

---

## The two launchd jobs

`lipost bot init` generates two plists (under `~/.config/lipost/launchd/`, symlinked into
`~/Library/LaunchAgents/`):

| Job | Fires | What it runs | Gated by |
| --- | --- | --- | --- |
| `local.lipost.post` | daily at `baseline_hour` | the post phase (pop oldest approved draft) | `active` |
| `local.lipost.generate` | every `generate_interval_hours` | the generate phase (drain `images/pending/`) | `generate_active` |

Both are **inert until armed**. Editing `baseline_hour` or `generate_interval_hours` via `lipost bot config`
automatically regenerates the plist and reloads launchd.

The launchd jobs call the hidden internal `_cron` entry points, not the interactive `lipost drafts run` —
the manual commands ignore the arm switches, the cron entry points honor them. See
[Single-file design](single-file-design.md).

---

## The jitter trick

`launchd` has no native jitter, so a post at exactly the same minute daily would look robotic. The trick:
launchd fires at `baseline_hour`, and the wrapper sleeps a uniform random `0…jitter_max_secs` before
posting. The actual post drifts inside a window each day. `lipost bot next` prints the next window. Set
`jitter_max_secs` to `0` for a deterministic fire at exactly `baseline_hour:00`.

A **min-hours-between-runs guard** (`min_hours_between_runs`, default 20h) prevents accidental double-posting:
the cron records `last_run_at` *before* posting, so a failed post or missing URN leaves the draft `approved`
and the next attempt is ~24h later. There are no in-run retries.

---

## The safety gates

After `bot init` the schedule is **live but inert**. Multiple independent gates keep it from posting:

| Gate | Where | Effect |
| --- | --- | --- |
| `active = false` | `bot.json` | master arm switch for the **post** cron (default off after init) |
| `generate_active = false` | `bot.json` | master arm switch for the **generate** cron (default off) |
| `TEMPLATE` marker | line 1 of `prompt.md` | while present, `drafts generate` refuses to run |
| `paused` | `state.json` | transient skip without unloading launchd (`bot pause` / `resume`) |

`active` vs `paused` vs `stop`: all three prevent posts at different layers — `active` is the durable master
switch in config, `paused` is a transient state flag, and `bot stop` unloads the launch agent entirely. The
full ladder of kill switches is in [Bot config reference](../03-cli-reference/bot-config-reference.md).

---

## Safety notes

- **`bypassPermissions` is wide.** Generate runs Claude with `--permission-mode bypassPermissions` so it
  doesn't hang on prompts. Don't keep secrets in the working directory.
- **Prompt injection via images.** Claude reads images you stage; a crafted image could try to override your
  prompt. Stage only images you trust.
- **The token expires (~60 days).** An expired token 401s; the draft stays `approved` for retry. Re-run
  `lipost auth`.

---

## Read next

- [The three layers](../01-overview/the-three-layers.md) — where the bot sits relative to the primitive and article layers
- [Bot config reference](../03-cli-reference/bot-config-reference.md) — every `bot.json` key, recipes, and kill switches
- [Runtime data layout](runtime-data-layout.md) — the draft `meta.json` schema and the queue on disk
