# lipost

A tiny, dependency-free Python CLI for posting text to your **personal LinkedIn feed** from the terminal.

- Single file, Python 3 stdlib only — no `pip install` required.
- OAuth 2.0 flow with a local redirect listener.
- Credentials and tokens are stored under `~/.config/linkedin-cli/`, **never** inside the repo.

## Install

```bash
git clone https://github.com/<your-username>/lipost.git
cd lipost
chmod +x lipost
# optional: put it on your PATH
ln -s "$PWD/lipost" ~/.local/bin/lipost
```

## One-time LinkedIn app setup

1. Go to <https://developer.linkedin.com> → **Create app**.
   - Every LinkedIn app must be associated with a Company Page (LinkedIn requirement). This does **not** affect where your posts go — posts always go to whichever member account authenticates. If you don't admin a page, create a throwaway one.
2. After creation, open your app and:
   - **Auth** tab → add `http://localhost:8765/callback` to *Authorized redirect URLs*.
   - **Products** tab → request both:
     - *Sign In with LinkedIn using OpenID Connect*
     - *Share on LinkedIn*

     Both auto-approve in seconds.
3. From the **Auth** tab, copy your **Client ID** and **Client Secret**.

## Configure credentials

Either set environment variables:

```bash
export LINKEDIN_CLIENT_ID=xxx
export LINKEDIN_CLIENT_SECRET=yyy
```

Or write a config file (recommended):

```bash
mkdir -p ~/.config/linkedin-cli
cp config.example.json ~/.config/linkedin-cli/config.json
chmod 600 ~/.config/linkedin-cli/config.json
# then edit ~/.config/linkedin-cli/config.json with your real values
```

## Usage

```bash
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
