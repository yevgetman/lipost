# lipost

A tiny, dependency-free Python CLI for posting text to your **personal LinkedIn feed** from the terminal.

- Single file, Python 3 stdlib only — no `pip install` required.
- OAuth 2.0 flow with a local redirect listener.
- Credentials and tokens are stored under `~/.config/linkedin-cli/`, **never** inside the repo.

## Quick start

```bash
git clone https://github.com/yevgetman/lipost.git
cd lipost
chmod +x lipost
./lipost init      # interactive setup: writes config + creates `lipost` on your PATH
lipost auth        # browser-based OAuth
lipost post "Hello LinkedIn!"
```

That's it for the happy path. Details below if you want them.

## One-time LinkedIn app setup

Before running `lipost init`, you need credentials from a LinkedIn developer app. This is a one-time, ~5-minute process. LinkedIn does not provide test credentials — every developer needs their own app.

### 1. Create the app

Go to <https://developer.linkedin.com/> and click **Create app**. You'll be asked for:

- **App name** — anything (e.g. `lipost`, `my-poster`). Only you will see this on the OAuth consent screen.
- **LinkedIn Page** *(required)* — LinkedIn forces every app to be associated with a Company Page, even for purely personal use. **This does not affect where your posts go** — posts always land on the personal feed of whoever authenticates. If you don't already admin a page, click *Create a new LinkedIn Page*, pick "Small business", and make a throwaway page (e.g., your name + " Dev"). You'll never use it again.
- **Privacy policy URL** — optional at creation time. You can leave it blank or paste any URL you control.
- **App logo** — required, square image ≥100px. Any image works; only you see it.
- **Legal agreement** — check the box, click **Create app**.

### 2. Add the redirect URL

In your new app, go to the **Auth** tab and under *Authorized redirect URLs for your app*, add:

```
http://localhost:8765/callback
```

This is where `lipost auth` runs a temporary local listener to capture the OAuth code. Save.

### 3. Request the API products

Go to the **Products** tab and request **both** of these (click *Request access* on each):

- **Sign In with LinkedIn using OpenID Connect** — gives the CLI your member ID at auth time.
- **Share on LinkedIn** — grants the `w_member_social` scope needed to post.

Both auto-approve within seconds for personal apps. You don't need *Marketing Developer Platform* — that's for posting on behalf of *other* users and is heavily gated.

### 4. Grab your credentials

Back on the **Auth** tab, copy the **Client ID** and **Client Secret**. `lipost init` will prompt for these in the next step.

### Where do posts go?

To your **personal LinkedIn feed** (the one your connections see at `linkedin.com/in/<you>`). The Company Page you attached to the app is purely an administrative association required by LinkedIn — it never appears in the post payload, and posts are not made to it. The CLI sets `author = "urn:li:person:<your-member-id>"`, which is captured from the OIDC `userinfo` endpoint at auth time.

## What `lipost init` does

- Prompts for your Client ID / Client Secret and writes them to `~/.config/linkedin-cli/config.json` with `chmod 600`.
- Offers to symlink the `lipost` script into a directory on your `PATH` (defaults to `~/.local/bin`, falls back to `~/bin` or `/usr/local/bin`). You can pick a different directory at the prompt.
- Warns you if the chosen directory isn't on your `PATH` and shows the line to add to your shell rc.

Re-run `lipost init` any time to update credentials or relink the binary.

## Manual configuration (alternative to `init`)

If you'd rather not run the interactive setup, you can do it by hand. Either set environment variables (they take precedence over the config file):

```bash
export LINKEDIN_CLIENT_ID=xxx
export LINKEDIN_CLIENT_SECRET=yyy
```

Or write the config file directly:

```bash
mkdir -p ~/.config/linkedin-cli
cp config.example.json ~/.config/linkedin-cli/config.json
chmod 600 ~/.config/linkedin-cli/config.json
# then edit ~/.config/linkedin-cli/config.json with your real values
```

## Usage

```bash
lipost init                                            # interactive first-time setup
lipost auth                                            # one-time browser OAuth
lipost whoami                                          # show authenticated person URN

# Text posts
lipost post "Hello LinkedIn!"                          # post text to your feed
lipost post -                                          # read post body from stdin
lipost post --dry-run "test"                           # show the request without sending

# Image posts (with optional caption + alt text)
lipost post --image photo.jpg "Caption goes here"
lipost post --image photo.png --alt "A red bicycle" "Out for a ride 🚴"
lipost post --image photo.jpg                         # image with no caption

# Delete
lipost delete urn:li:share:1234567890
```

### Image posts

`--image PATH` (or `-i PATH`) attaches a single image to a post. JPEG and PNG are the safe choices. The caption (positional text) is optional — you can post just an image. `--alt "TEXT"` sets accessibility alt text and is recommended.

Under the hood the CLI does the standard 3-step LinkedIn image flow: initialize an upload to get an image URN, PUT the bytes, then create the post with `content.media.id` set to that URN. No extra API products or scopes are required beyond what `lipost auth` already grants.

## Testing without spamming your feed

LinkedIn does **not** offer a sandbox / test environment for the Posts API. Two safe ways to try things out:

1. **Dry run.** Use `--dry-run` (or `-n`) to print the exact JSON that would be sent without hitting LinkedIn at all. No rate-limit cost, no post created.
   ```bash
   lipost post --dry-run "this is a test"
   ```
2. **Post then delete.** When `post` succeeds, the CLI prints the URN and a ready-to-paste delete command. Run it immediately to remove the post:
   ```bash
   $ lipost post "test from CLI"
   posted: urn:li:share:7185023485712384000
   url:    https://www.linkedin.com/feed/update/urn:li:share:7185023485712384000/
   to delete: lipost delete urn:li:share:7185023485712384000

   $ lipost delete urn:li:share:7185023485712384000
   deleted: urn:li:share:7185023485712384000
   ```
   Delivery to your network's feeds isn't instant; deleting within seconds makes it very unlikely anyone saw it.

## Where do posts go?

To your **personal feed** — the one your connections see at `linkedin.com/in/<you>`.

The post payload sets `author = "urn:li:person:<your-member-id>"`, where the member ID is captured at auth time from the OIDC `userinfo` endpoint. The Company Page attached to the app for administrative reasons is **not** in the post payload and is not posted to.

To post to a Company Page instead, you'd need the `w_organization_social` scope and a different author URN — out of scope for this tool.

## Token lifetime

LinkedIn member tokens last ~60 days. When yours expires, just re-run `lipost auth`.

## Files this CLI writes

| Path | Purpose |
| --- | --- |
| `~/.config/linkedin-cli/config.json` | client id/secret (chmod 600) |
| `~/.config/linkedin-cli/token.json`  | OAuth access token + member URN (chmod 600) |

Nothing is ever written into the repo.

## License

MIT — see [LICENSE](LICENSE).
