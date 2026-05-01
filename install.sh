#!/usr/bin/env bash
# Install lipost: create a symlink in the first writable PATH dir we find.
# Idempotent — re-running just refreshes the symlink.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="${REPO_DIR}/bin/lipost"

if [[ ! -x "$SCRIPT" ]]; then
  chmod +x "$SCRIPT"
fi

CANDIDATES=(
  "${HOME}/.local/bin"
  "${HOME}/bin"
  "/usr/local/bin"
)

# Prefer a candidate that is BOTH on PATH and writable.
target=""
IFS=":" read -r -a path_parts <<< "${PATH:-}"
for c in "${CANDIDATES[@]}"; do
  for p in "${path_parts[@]}"; do
    if [[ "$c" == "$p" && -d "$c" && -w "$c" ]]; then
      target="$c"
      break 2
    fi
  done
done

# If nothing was both on PATH and writable, fall back to the first writable one.
if [[ -z "$target" ]]; then
  for c in "${CANDIDATES[@]}"; do
    if [[ -d "$c" && -w "$c" ]]; then
      target="$c"
      break
    fi
  done
fi

# Last resort: create ~/.local/bin.
if [[ -z "$target" ]]; then
  target="${HOME}/.local/bin"
  mkdir -p "$target"
fi

link="${target}/lipost"
if [[ -L "$link" || -e "$link" ]]; then
  rm -f "$link"
fi
ln -s "$SCRIPT" "$link"
echo "Linked $link → $SCRIPT"

# Warn if target isn't on PATH.
on_path=0
for p in "${path_parts[@]}"; do
  if [[ "$target" == "$p" ]]; then
    on_path=1
    break
  fi
done
if [[ $on_path -eq 0 ]]; then
  echo
  echo "warning: $target is not on your PATH. Add it to your shell rc, e.g.:"
  echo "  export PATH=\"$target:\$PATH\""
fi

echo
echo "Next:"
echo "  lipost init     # OAuth + LinkedIn credentials"
echo "  lipost auth     # browser-based OAuth"
echo "  lipost post \"hello world\""
echo
echo "Optional:"
echo "  lipost article <url>     # one-shot article-to-post via Claude"
echo "  lipost bot init          # autonomous poster (macOS launchd)"
