#!/bin/bash
# Removes what install.sh set up: the login item and the KeepingYouAwake app. Leaves power settings alone.
set -euo pipefail

say() { printf '==> %s\n' "$1"; }

[ "$(/usr/bin/id -u)" -ne 0 ] || { printf 'error: do not run as root.\n' >&2; exit 1; }

BREW=""
for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
  [ -x "$b" ] && BREW="$b" && break
done
PATH=/usr/bin:/bin:/usr/sbin:/sbin
export PATH

if /usr/bin/osascript -e 'tell application "System Events" to delete (every login item whose name is "KeepingYouAwake")' >/dev/null 2>&1; then
  say "Removed the login item (if there was one)"
else
  say "Could not remove the login item (Automation permission denied?); remove it in System Settings > General > Login Items"
fi
if /usr/bin/pgrep -x KeepingYouAwake >/dev/null 2>&1; then
  /usr/bin/osascript -e 'quit app "KeepingYouAwake"' >/dev/null 2>&1 || true
fi

if [ -n "$BREW" ] && "$BREW" list --cask keepingyouawake >/dev/null 2>&1; then
  "$BREW" uninstall --cask keepingyouawake
  say "Uninstalled KeepingYouAwake"
else
  say "KeepingYouAwake is not a Homebrew install here; remove it from /Applications yourself if wanted"
fi
