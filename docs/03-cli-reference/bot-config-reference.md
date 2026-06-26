# Bot config reference

All bot settings live in `~/.config/lipost/bot.json`. Show them with `lipost bot config`; update one with
`lipost bot config <key> <value>` (the value is validated and cast to the right type). Editing
`baseline_hour` or `generate_interval_hours` automatically regenerates the plist and reloads launchd.

For how these keys drive the schedule, see [The bot & launchd](../02-architecture/the-bot-and-launchd.md).

---

## Config keys

| Key | Default | What it controls |
| --- | --- | --- |
| `active` | `false` | Master arm switch for the **post** cron. `lipost drafts run` ignores this; the cron honors it. |
| `generate_active` | `false` | Master arm switch for the **generate** cron (auto-drains `images/pending/`). Manual `drafts generate` ignores it. |
| `generate_interval_hours` | `8` | How often the generate cron fires. Min `1`. |
| `baseline_hour` | `9` | Hour (0–23) at which launchd fires, before jitter. |
| `jitter_max_secs` | `43200` (12h) | Max seconds the wrapper sleeps after baseline before posting. `0` = deterministic fire at exactly `baseline_hour:00`. |
| `min_hours_between_runs` | `20` | If the previous run started fewer than this many hours ago, the cron skips. |
| `permission_mode` | `bypassPermissions` | Passed to `claude -p` during generate as `--permission-mode`. |
| `claude_model` | `claude-opus-4-7` | Passed to `claude -p` as `--model`. Opus by default — image interpretation benefits from the strongest model. |

---

## Common recipes

```bash
# Post strictly between 11:00 and 17:00 each day
lipost bot config baseline_hour 11
lipost bot config jitter_max_secs 21600

# Post at exactly 09:00 every day (no jitter)
lipost bot config jitter_max_secs 0

# Use Sonnet during generate (faster, cheaper, weaker at images)
lipost bot config claude_model claude-sonnet-4-6

# Turn on the auto-generate cron (drains images/pending/ every 8h)
lipost bot config generate_active true

# Run the auto-generate cron every 4h
lipost bot config generate_interval_hours 4
```

---

## Kill switches (in order of severity)

| You want to… | Run |
| --- | --- |
| Disarm the post schedule (durable) | `lipost bot config active false` |
| Disarm the auto-generate cron | `lipost bot config generate_active false` |
| Pause transiently for a few days | `lipost bot pause` |
| Drain the approved queue without posting | Hand-edit each `drafts/<slug>/meta.json` `"status"` to `"rejected"`, or `rm -rf drafts/<slug>` |
| Take the bot off the schedule completely | `lipost bot stop` |
| Remove the install, keep config + drafts + history | `lipost bot uninstall` |
| Nuclear — remove everything | `lipost bot uninstall && rm -rf ~/.config/lipost ~/.local/share/lipost ~/Library/Logs/lipost.log` |

`active` (durable config switch) vs `paused` (transient state flag) vs `stop` (unloads the launch agent) each
prevent posts at a different layer.

---

## Read next

- [The bot & launchd](../02-architecture/the-bot-and-launchd.md) — the scheduling mechanics these keys feed
- [Command reference](command-reference.md) — the `lipost bot` command surface
- [Runtime data layout](../02-architecture/runtime-data-layout.md) — where `bot.json` and `state.json` live
