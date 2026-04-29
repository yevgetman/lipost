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

Before running `lipost init`, you need credentials from a LinkedIn developer app:

1. Go to <https://developer.linkedin.com> → **Create app**.
   - Every LinkedIn app must be associated with a Company Page (LinkedIn requirement). This does **not** affect where your posts go — posts always go to whichever member account authenticates. If you don't admin a page, create a throwaway one.
2. Open your app and:
   - **Auth** tab → add `http://localhost:8765/callback` to *Authorized redirect URLs*.
   - **Products** tab → request both:
     - *Sign In with LinkedIn using OpenID Connect*
     - *Share on LinkedIn*

     Both auto-approve in seconds.
3. From the **Auth** tab, copy your **Client ID** and **Client Secret** — `lipost init` will prompt for them.

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
lipost init                          # interactive first-time setup
lipost auth                          # one-time browser OAuth
lipost whoami                        # show authenticated person URN
lipost post "Hello LinkedIn!"        # post text to your feed
echo "multi-line body" | lipost post -
```

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
