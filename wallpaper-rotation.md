# Wallpaper rotation on XMonad — options & notes

Reference notes to help pick a rotation strategy. Nothing here is wired up
beyond the **common helper** below; the rest are sketches.

---

## 1. Current state of the box

- **WM:** XMonad on X11 (`XDG_SESSION_TYPE=x11`, `DISPLAY=:0`).
- **xmonad config:** `~/.config/xmonad/xmonad.hs`. Already does:
  - `mod+w` → `feh --bg-fill --randomize ~/dotfiles/wallpapers/*.png` (keybind, line 54)
  - `startupHook` runs the same on session start (`spawnOnce`, line 102)
- **Wallpapers:** `~/dotfiles/wallpapers/` (9 PNGs as of writing).
- **Wallpaper tools installed:** `feh`, `nitrogen`, `wal` (pywal). Missing: `xwallpaper`, `hsetroot`, `variety`, `swaybg`.
- **Generic helper kept on disk:** `~/.local/bin/wallpaper-rotate` (executable; see §2). Reusable from any of the options below.
- **Removed:** the systemd user timer + service that briefly drove rotation
  (see §3). Nothing systemd-related remains in `~/.config/systemd/user/`.

---

## 2. Common helper: `~/.local/bin/wallpaper-rotate`

Picks one random image from `$WALLPAPER_DIR` (default
`~/dotfiles/wallpapers`) and applies it via `feh --bg-fill`. All the
options below can call this — the orchestration changes, the helper
doesn't.

```bash
#!/usr/bin/env bash
# Pick one random wallpaper from $WALLPAPER_DIR and set it via feh.
set -euo pipefail

DIR="${WALLPAPER_DIR:-$HOME/dotfiles/wallpapers}"
export DISPLAY="${DISPLAY:-:0}"

img=$(find "$DIR" -type f \
        \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) \
        -print0 | shuf -z -n1 | tr -d '\0')

[ -n "$img" ] || { echo "wallpaper-rotate: no images in $DIR" >&2; exit 1; }

exec feh --no-fehbg --bg-fill "$img"
```

`--no-fehbg` keeps feh from rewriting `~/.fehbg` on every rotation
(harmless, but noisy if the file is in version control).

To wire pywal in instead, replace the last line with:

```bash
exec wal -i "$img" -q     # also retheme terminal/Emacs/etc. via pywal
```

(Drop `-n` if you want wal to set the wallpaper itself; otherwise pair
with a `feh` call before/after.)

---

## 3. Option A — systemd user timer (the route already torn down)

How it worked:

- `~/.config/systemd/user/wallpaper.service` — `Type=oneshot`, ran the
  helper.
- `~/.config/systemd/user/wallpaper.timer` — fired every 15 min
  (`OnUnitActiveSec=15min`), `Persistent=true` so it caught up after
  downtime, `OnBootSec=2min` for the first kick.
- Enabled with `systemctl --user enable --now wallpaper.timer`.

```ini
# wallpaper.service
[Unit]
Description=Rotate desktop wallpaper (random pick via feh)

[Service]
Type=oneshot
Environment=DISPLAY=:0
ExecStart=%h/.local/bin/wallpaper-rotate
```

```ini
# wallpaper.timer
[Unit]
Description=Rotate wallpaper every 15 minutes

[Timer]
OnBootSec=2min
OnUnitActiveSec=15min
Persistent=true
Unit=wallpaper.service

[Install]
WantedBy=timers.target
```

**Why I dropped it (per request):** wallpaper rotation should live in
the WM/shell layer, not in the init system. Pros for record:
introspectable via `systemctl --user list-timers` and
`journalctl --user -u wallpaper.service`, survives reboots cleanly,
catches up after sleep. Con: an entirely separate layer of plumbing
disconnected from the X session.

---

## 4. Option B — shell loop spawned from `startupHook` (recommended)

A tiny shell loop launched once per xmonad session.

`~/.local/bin/wallpaper-loop`:

```bash
#!/usr/bin/env bash
# Long-running loop: rotate wallpaper every $WALLPAPER_INTERVAL seconds.
INTERVAL="${WALLPAPER_INTERVAL:-900}"   # 15 minutes default
while sleep "$INTERVAL"; do
  ~/.local/bin/wallpaper-rotate || true
done
```

In `xmonad.hs`, in `startupHook`:

```haskell
spawnOnce "wallpaper-loop"
```

(`wallpaper-loop` lives in `~/.local/bin`, which is on PATH per
`~/.bashrc`, so no full path needed — but double-check that the X
session inherits that PATH; if not, use `$HOME/.local/bin/wallpaper-loop`.)

**Pros**

- Two lines of bash, one line of Haskell.
- Easy to introspect: `pgrep -af wallpaper-loop`.
- Easy to pause/disable: `pkill -f wallpaper-loop`.
- Easy to change interval: edit the script, kill the loop, restart
  xmonad (or just relaunch the loop manually).
- Survives xmonad recompiles cleanly: `spawnOnce`'s state file in
  `~/.cache/xmonad/` prevents a second loop from spawning on `mod-q`.

**Cons**

- A long-lived `bash` PID hanging around (`ps` clutter).
- If the loop dies in a weird way (OOM, accidental kill), no
  auto-respawn until next xmonad start.
- Editing the loop script while it's running has no effect until
  restart — and `spawnOnce`'s cache means xmonad won't relaunch on its
  own. Workflow after edits: `pkill -f wallpaper-loop && wallpaper-loop
  &disown`.
- `sleep` is uninterruptible from outside without killing the whole
  process — no clean "rotate now" signal short of `pkill -USR1`
  plumbing (overkill).

---

## 5. Option C — `XMonad.Util.Timer` in `xmonad.hs`

Rotation lives entirely inside xmonad's event loop. No separate
process, no shell loop. Uses xmonad-contrib's `XMonad.Util.Timer` plus
extensible state to hold the current `TimerId`.

**Sketch — verify against your `xmonad-contrib` version before pasting:**

```haskell
{-# LANGUAGE DeriveDataTypeable #-}
import Data.Monoid              (All(..))
import Data.Typeable            (Typeable)
import XMonad.Util.Timer        (TimerId, startTimer, handleTimer)
import qualified XMonad.Util.ExtensibleState as XS

newtype WallTimer = WallTimer TimerId deriving Typeable
instance ExtensionClass WallTimer where
  initialValue = WallTimer 0

wallInterval :: Rational
wallInterval = 15 * 60   -- seconds

armWallTimer :: X ()
armWallTimer = startTimer wallInterval >>= XS.put . WallTimer

wallEventHook :: Event -> X All
wallEventHook e = do
  WallTimer t <- XS.get
  handleTimer t e $ do
    spawn "~/.local/bin/wallpaper-rotate"
    armWallTimer
    pure Nothing
  pure (All True)
```

Then wire into the main config:

```haskell
main = xmonad $ def
  { startupHook    = startupHook def <+> armWallTimer <+> spawnOnce "picom"
  , handleEventHook = handleEventHook def <+> wallEventHook
  , ...
  }
```

**Pros**

- The most "xmonad-native" answer: zero extra processes, lifecycle is
  the xmonad lifecycle.
- Restarts cleanly on `mod-q` (recompile re-arms the timer).
- All wallpaper logic is in one file alongside the rest of the WM.

**Cons**

- ~25 lines of Haskell, including extensible-state plumbing.
- Changing the interval requires `mod-q` (recompile).
- Harder to inspect than `ps`; you can't tell from outside how long
  until next fire.
- No obvious pause without writing a toggle keybind that flips a `Bool`
  in extensible state.
- `XMonad.Util.Timer` is fine but has historically been a bit fiddly
  across xmonad-contrib versions; expect to tweak the snippet.

---

## 6. Option D — shell loop + toggle keybind (option B + 5 lines)

Same loop as §4, but add a keybind that kills or restarts it on demand.

`xmonad.hs` keybind sketch:

```haskell
, ((myModMask .|. shiftMask, xK_w),
   spawn "pgrep -f wallpaper-loop >/dev/null && pkill -f wallpaper-loop || wallpaper-loop &")
```

(That `&` at the end of a `spawn` string is harmless — `spawn` runs
through `/bin/sh -c`, so shell backgrounding works.)

**Pros / cons:** same as option B, plus the ability to pause auto-rotate
during screen-shares, presentations, etc., without dropping to a shell.
Costs one keybind slot.

---

## 7. Option E — event-driven (logHook), brief

Replace "every 15 min" with "every Nth workspace switch" or "every
focus change of type X". Hook into xmonad's `logHook` (which fires on
those events) and increment a counter in extensible state; when it
hits N, rotate.

- **Pros:** novel; no background process; cadence ties to your usage.
- **Cons:** unpredictable wall-clock cadence; not what "every now and
  then" usually means; if you idle, wallpaper never changes.
- **Verdict:** mention it, don't pick it unless the time-driven feel
  bothers you.

---

## 8. Comparison

| Option                        | Layer            | Code     | Introspect          | Recompile? | Pause     |
|-------------------------------|------------------|----------|---------------------|------------|-----------|
| A. systemd user timer         | init system      | small    | `journalctl`/`list-timers` | n/a        | `disable` |
| **B. shell loop in startup**  | shell + xmonad   | tiny     | `pgrep`             | no         | `pkill`   |
| C. `XMonad.Util.Timer`        | xmonad/Haskell   | medium   | hard                | yes        | requires extra code |
| D. B + toggle keybind         | shell + xmonad   | tiny+    | `pgrep`             | once       | keybind   |
| E. logHook event-driven       | xmonad/Haskell   | medium   | hard                | yes        | n/a (event-driven) |

---

## 9. Decision points to settle before wiring anything

1. **Interval.** Default 15 min. Probably 30 min is calmer. 5 min is too
   busy.
2. **Toggle keybind** (option D) — yes/no? Useful if you screen-share or
   present from this machine; pure clutter otherwise.
3. **Pywal coupling.** Plain `feh` set vs `wal -i` retheme on each
   change. The `~/.bashrc` line `#wal -R -q` (line 102) is commented,
   suggesting pywal isn't currently active — keep it that way unless you
   want to opt back in.
4. **Inline vs helper script.** `~/.local/bin/wallpaper-rotate` exists
   and works. Could instead inline the logic into `xmonad.hs` (option C)
   or `wallpaper-loop` (option B). Helper-script approach keeps the
   "pick + apply" logic reusable from a keybind and from any rotation
   driver.
5. **Wallpaper formats.** Existing keybind globs `*.png` only. The
   helper script accepts `png|jpg|jpeg|webp`. Decide whether to widen
   `xmonad.hs:54` and `xmonad.hs:102` for consistency.

---

## 10. My recommendation

**Option B (shell loop in `startupHook`)** unless you specifically want
the elegance of doing it inside xmonad's event loop. "Mostly via shell
or xmonad" maps cleanly onto B; option C is cleaner-on-paper but the
Haskell investment doesn't pay back for a wallpaper rotator. Add option
D's toggle keybind if you ever screen-share.

Total moving parts to add for option B: one ~5-line shell script and
one `spawnOnce` line in `xmonad.hs`. The helper at
`~/.local/bin/wallpaper-rotate` already does the actual work.
