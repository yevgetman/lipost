# Command reference

The full `lipost` command surface, grouped by layer. Run `lipost <cmd> --help` for exact flags, or
`lipost cheatsheet` for a curated short list. Commands map one-to-one to the `cmd_*` functions in
`bin/lipost`.

---

## Layer 1 — primitives

| Command | What it does |
| --- | --- |
| `lipost init` | OAuth credentials + first-time setup; migrates legacy paths; offers to symlink onto `PATH` |
| `lipost auth` | Run the LinkedIn OAuth browser flow (one redirect); writes `token.json` |
| `lipost whoami` | Show the authenticated member URN |
| `lipost post <text>` | Publish a text post (`-` reads body from stdin) |
| `lipost edit <urn> <text>` | Edit a post's commentary text (image/visibility locked after publish) |
| `lipost delete <urn>` | Delete a post by URN |

Key `post` flags:

```bash
lipost post "Hello LinkedIn!"
lipost post -                          # read body from stdin
lipost post --dry-run "test"           # print the JSON, send nothing
lipost post --image photo.jpg "Caption goes here"
lipost post --image photo.png --alt "A red bicycle" "Out for a ride"
lipost post --queue "draft for later"          # enqueue, status=approved
lipost post --queue-pending "needs a pass"     # enqueue, status=pending_approval
```

`--queue` is text-only and does **not** require the bot daemon — it just writes a draft to the queue you can
post later with `lipost drafts run`. For auth and version-error details see
[LinkedIn API & auth](../02-architecture/linkedin-api-and-auth.md).

---

## Layer 2 — the article skill

| Command | What it does |
| --- | --- |
| `lipost article [url]` | URL → Claude → reviewed draft → post or queue (prompts for the URL if omitted) |

Key flags:

```bash
lipost article https://blog.example.com/post   # generate + review + post
lipost article --with-image https://...         # also generate an OpenAI image
lipost article --image pic.jpg https://...      # use your own image with the draft
lipost article --dry-run https://...            # everything except the publish
lipost article --queue https://...              # at [q] → enqueue as approved
lipost article --queue-pending https://...      # at [q] → enqueue as pending_approval
```

Requires `claude` on `PATH`; `--with-image` requires `OPENAI_API_KEY`. The persona prompt is
`~/.config/lipost/prompt.md` (override with `LIPOST_PROMPT`).

---

## Layer 3 — drafts queue + bot

### `lipost drafts <action>` (default action: `list`)

| Command | What it does |
| --- | --- |
| `lipost drafts` / `lipost drafts list` | List drafts grouped by status (`--status approved` to filter) |
| `lipost drafts add` | Enqueue a text-only draft from `--text` or stdin |
| `lipost drafts review` | Walk pending drafts in the TUI (`a/r/e/g/s/q`) |
| `lipost drafts generate` | Drain `images/pending/` into drafts (one Claude call per image) |
| `lipost drafts run` | Post the next approved draft now (`--no-fire` to inspect without posting) |

### `lipost bot <action>`

| Command | What it does |
| --- | --- |
| `lipost bot init` | Install the two launchd jobs, write `bot.json`, migrate legacy state |
| `lipost bot status` | One-screen status (arm switches, deps, launchd, prompt, draft counts) |
| `lipost bot config [key value]` | Show or update a config key (validated; see [Bot config reference](bot-config-reference.md)) |
| `lipost bot pause` / `resume` | Transient skip without unloading launchd |
| `lipost bot start` / `stop` | Load / unload both launchd jobs |
| `lipost bot next` | Print the next scheduled fire window |
| `lipost bot logs [-f]` | Tail `~/Library/Logs/lipost.log` |
| `lipost bot uninstall` | Remove the install but keep config, drafts, and history |

### Shared tooling

| Command | What it does |
| --- | --- |
| `lipost posts` | List past posts (URN history); `--open` opens the most recent on LinkedIn |
| `lipost images` | List pending/skipped staged images; `--open` opens the pending dir in Finder |
| `lipost prompt` | Edit `~/.config/lipost/prompt.md` in `$EDITOR` |
| `lipost style` | Edit `user_style.md`; `--show` previews the combined layer; `--baked` shows `share/style.md` |
| `lipost cheatsheet` | Print the curated short command list |

---

## Read next

- [Bot config reference](bot-config-reference.md) — every `bot.json` key, recipes, and kill switches
- [The bot & launchd](../02-architecture/the-bot-and-launchd.md) — what the bot commands drive
- [LinkedIn API & auth](../02-architecture/linkedin-api-and-auth.md) — what `auth` / `post` do under the hood
