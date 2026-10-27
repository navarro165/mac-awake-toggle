#!/bin/bash
# Sets up an on-demand keep-awake toggle in the menu bar (KeepingYouAwake from Homebrew), starts it at login,
# and makes sure the Apple menu Sleep item is not disabled by a leftover system-wide SleepDisabled flag.
# Safe to re-run.
set -euo pipefail

say() { printf '==> %s\n' "$1"; }
die() { printf 'error: %s\n' "$1" >&2; exit 1; }

APP=/Applications/KeepingYouAwake.app
# Notarized, Apple-anchored, and signed by the KeepingYouAwake developer (Marcel Dierkes, team 5KESHV9W85).
REQ='notarized and anchor apple generic and certificate leaf[subject.OU] = "5KESHV9W85"'

[ "$(/usr/bin/id -u)" -ne 0 ] || die "do not run as root; run as the user whose menu bar should show the toggle."
[ "$(/usr/bin/uname -s)" = "Darwin" ] || die "this only runs on macOS."

# Prefer Homebrew's standard locations over whatever is first on PATH, then pin PATH to system tools so a
# same-named binary earlier on PATH cannot stand in for codesign, pmset and the rest.
BREW=""
for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
  [ -x "$b" ] && BREW="$b" && break
done
[ -n "$BREW" ] || die "Homebrew is required (looked in /opt/homebrew and /usr/local): https://brew.sh"
PATH=/usr/bin:/bin:/usr/sbin:/sbin
export PATH

verify_app() {
  /usr/bin/codesign --verify --deep --strict -R="$REQ" "$APP" 2>/dev/null \
    || die "$APP is not the notarized KeepingYouAwake build signed by team 5KESHV9W85; stopping."
}

if [ -d "$APP" ]; then
  say "KeepingYouAwake already installed"
else
  say "Installing KeepingYouAwake"
  "$BREW" install --cask homebrew/cask/keepingyouawake
fi
verify_app

# SleepDisabled is system-wide; while it is 1 macOS greys out Apple menu > Sleep. It is usually left behind by
# `pmset -a disablesleep 1` or a tool that keeps a Mac awake with the lid shut.
power=$(/usr/sbin/ioreg -n IOPMrootDomain -r -d 1)
if grep -q '"SleepDisabled" = Yes' <<<"$power"; then
  say "SleepDisabled is on, so Apple menu > Sleep is greyed out."
  say "If another tool (a lid-closed keep-awake daemon, an MDM profile) set it on purpose, it may set it again."
  reply=n
  if [ -t 0 ]; then
    read -r -p "Turn it off now with 'sudo pmset -a disablesleep 0'? [y/N] " reply || reply=n
  fi
  case "$reply" in
    [yY]*)
      if /usr/bin/sudo /usr/bin/pmset -a disablesleep 0; then
        say "SleepDisabled is now off"
      else
        die "sudo pmset failed; SleepDisabled is still on"
      fi
      ;;
    *) say "Left it on; run 'sudo pmset -a disablesleep 0' later to re-enable Sleep" ;;
  esac
else
  say "SleepDisabled is off; Apple menu > Sleep is available"
fi

# Re-check right before the app is persisted and launched, since the prompt above can wait indefinitely.
verify_app

# macOS may ask once to let your terminal control System Events; that is what adds the login item.
items=$(/usr/bin/osascript -e 'tell application "System Events" to get the name of every login item' 2>/dev/null || true)
if tr ',' '\n' <<<"$items" | sed 's/^ *//' | grep -qx 'KeepingYouAwake'; then
  say "Already starts at login"
else
  say "Adding KeepingYouAwake to login items"
  /usr/bin/osascript -e "tell application \"System Events\" to make login item at end with properties {path:\"$APP\", hidden:false}" >/dev/null \
    || say "Could not add the login item; enable 'Start at Login' in KeepingYouAwake's preferences instead"
fi

/usr/bin/open -a "$APP"
say "Done. Click the cup in the menu bar to keep the Mac awake; click again to allow normal sleep."
