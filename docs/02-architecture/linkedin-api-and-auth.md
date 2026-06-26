# LinkedIn API & auth

lipost talks to LinkedIn's REST API directly over `urllib` (no SDK). This doc covers the OAuth flow, the
scopes, the token lifetime, the monthly API-version pin (the single most common source of failures), and the
endpoints used.

---

## One-time developer-app setup

LinkedIn provides no shared test credentials, so every user creates their own developer app (~5 minutes) at
<https://developer.linkedin.com/>. The app needs:

- An **Authorized redirect URL** of `http://localhost:8765/callback` (the loopback port lipost listens on
  during `auth`).
- Two products requested (auto-approved for personal apps):
  - **Sign In with LinkedIn using OpenID Connect** — yields your member ID at auth time.
  - **Share on LinkedIn** — grants the `w_member_social` scope needed to post.

The **Client ID** and **Client Secret** from the app's Auth tab go into `auth.json` (via `lipost init`, or
the `LINKEDIN_CLIENT_ID` / `LINKEDIN_CLIENT_SECRET` env vars, which take precedence). The required *LinkedIn
Page* field on the app does **not** affect where posts go — posts always land on the authenticating member's
personal feed.

---

## The OAuth flow (`lipost auth`)

```
SCOPES       = "openid profile w_member_social"
REDIRECT_URI = http://localhost:8765/callback
```

1. lipost opens the browser to LinkedIn's authorize URL with the client ID, scopes, and redirect.
2. A tiny `http.server` listens on `localhost:8765` for the one redirect carrying the `code`.
3. lipost exchanges the code for an access token, calls `GET /v2/userinfo` to resolve the member URN, and
   writes both to `~/.config/lipost/token.json` (`chmod 600`).

**Token lifetime is ~60 days.** When it expires, `post` returns 401; re-run `lipost auth`. In the bot, an
expired token leaves the draft `approved` for the next scheduled retry.

---

## The monthly version pin (read this when posting breaks)

Every API call sends a `LinkedIn-Version` header. LinkedIn pins each call to a **monthly version**
(`LINKEDIN_API_VERSION = "202604"` at time of writing) and rotates them on a ~12-month deprecation window.

> If image upload, post, edit, or delete fails with **HTTP 426 / `NONEXISTENT_VERSION`**, edit
> `LINKEDIN_API_VERSION` near the top of `bin/lipost` to a current month (`YYYYMM`). Available versions:
> the [LinkedIn API versioning docs](https://learn.microsoft.com/en-us/linkedin/marketing/versioning).

This is a one-line code change, not a config setting — it lives in the source so a stale pin is fixed at the
source of truth.

---

## Endpoints used

| Operation | Method + endpoint | Notes |
| --- | --- | --- |
| Resolve member | `GET /v2/userinfo` | at auth time; yields the person URN |
| Initialize image upload | `POST /rest/images?action=initializeUpload` | sends `LinkedIn-Version` |
| Create post | `POST /rest/posts` | URN returned in the `x-restli-id` response header |
| Edit commentary | `POST /rest/posts/{urn}` | text only — image and visibility are locked after publish |
| Delete post | `DELETE /rest/posts/{urn}` | |

All `/rest/*` calls carry the `LinkedIn-Version` header; a stale value is what triggers the 426 above.

`lipost post --dry-run` prints the exact JSON and headers that *would* be sent without hitting LinkedIn —
the safe way to test, since LinkedIn offers no sandbox. The other safe path is post-then-delete: a successful
`post` prints the URN and a ready-to-paste `lipost delete` command.

---

## Read next

- [Runtime data layout](runtime-data-layout.md) — where `auth.json` and `token.json` live (and their permissions)
- [Command reference](../03-cli-reference/command-reference.md) — `init`, `auth`, `whoami`, `post`, `edit`, `delete`
- [Single-file design](single-file-design.md) — where these constants live in the source
