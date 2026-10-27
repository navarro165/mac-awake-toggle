# mac-awake-toggle

Keep a Mac awake only when you want to, with one click in the menu bar, while Apple menu > Sleep keeps working.

It sets up [KeepingYouAwake](https://github.com/newmarcel/KeepingYouAwake) (a free, open-source menu bar app by Marcel Dierkes), starts it at login, and fixes the most common reason the Sleep item is greyed out.

## The problem

The usual ways to stop a Mac sleeping each break something:

* `sudo pmset -a disablesleep 1` (and tools built on it, often used to keep a laptop working with the lid shut) sets a system-wide `SleepDisabled` flag. While it is on, **Apple menu > Sleep is greyed out**, and the flag has no per-power-source form.
* `sudo pmset -c sleep 0` stops idle sleep on power permanently, with no quick way to turn it back on.
* A hot corner set to "Disable Screen Saver" only stops the screen saver. It does not prevent display sleep or system sleep.

## What you get

```
Menu bar cup, filled  = stays awake (no idle sleep, display stays on)
Menu bar cup, empty   = normal sleep settings apply
Apple menu > Sleep    = always works
```

KeepingYouAwake runs Apple's `caffeinate` while it is on, which holds `PreventUserIdleSystemSleep` and `PreventUserIdleDisplaySleep` assertions. Those block idle sleep only: choosing Sleep from the Apple menu, or closing the lid with no external display attached, still sleeps the Mac.

You can also switch it from a script or a Shortcut:

```sh
open "keepingyouawake:///activate"
open "keepingyouawake:///deactivate"
```

Any app, and any web page you allow to open it, can use that URL scheme too, which can keep the Mac awake and delay auto-lock. Do not tick "always allow" when a browser asks to open KeepingYouAwake.

## Install

Requirements: macOS and [Homebrew](https://brew.sh). Tested on macOS 26 on Apple silicon.

```sh
git clone https://github.com/navarro165/mac-awake-toggle.git
cd mac-awake-toggle
./install.sh
```

`install.sh`:

1. Installs KeepingYouAwake with `brew install --cask keepingyouawake` if it is missing.
2. Checks with `codesign` that the app is notarized and signed by the KeepingYouAwake developer (Marcel Dierkes, team `5KESHV9W85`), and stops if not.
3. If `SleepDisabled` is on, says so and asks before running `sudo pmset -a disablesleep 0`. Nothing else in your power settings is changed.
4. Adds the app to your login items. macOS may ask once whether your terminal may control System Events; that permission stays after uninstall, and you can revoke it in System Settings > Privacy & Security > Automation.
5. Opens the app.

Re-running it is safe.

## Uninstall

```sh
./uninstall.sh
```

Removes the login item and uninstalls the app. It does not touch power settings.

## Caveats

* If something else turned `SleepDisabled` on deliberately (a lid-closed keep-awake daemon, a management profile), it may turn it on again. Find and remove that first.
* On a managed Mac, display sleep and screen lock timers may be enforced by your organisation and are not changed here.

## Security notes

* The scripts themselves make no network requests. Homebrew fetches the app (and may update itself), and the app checks for its own updates.
* `sudo` is used only for `/usr/bin/pmset -a disablesleep 0`, only after you answer `y`, and the script stops if it fails.
* The scripts call system tools by absolute path and pin `PATH`, so a same-named program earlier on your `PATH` cannot stand in for them.
* The app is checked before install finishes and again right before it is added to login items and opened: it must be notarized and signed by team `5KESHV9W85`. This proves who signed it, not which version it is.

## License

MIT
