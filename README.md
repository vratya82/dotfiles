# Dotfiles Utilities

This repository now includes a **CLI Pomodoro timer** designed to run well in **Windows 11 terminals** (PowerShell, Command Prompt, or Windows Terminal).

## Pomodoro CLI Timer

Path: `scripts/pomodoro_timer.py`

### 1) What it uses

- **Python 3.10+** (standard library only).
- **`argparse`** to parse command-line options.
- **`time`** for the 1-second countdown loop.
- **`msvcrt` on Windows** for single-key controls without pressing Enter.
- **`winsound` on Windows** for native beep notifications.
- A **POSIX fallback** (`select` + terminal bell) for non-Windows environments.

No third-party packages are required.

### 2) How to run on Windows 11

From this repo root:

```powershell
python .\scripts\pomodoro_timer.py
```

Optional arguments:

```powershell
python .\scripts\pomodoro_timer.py --work 30 --short-break 5 --long-break 20 --cycles 6
```

Defaults:

- `--work 25`
- `--short-break 5`
- `--long-break 15`
- `--cycles 4`

### 3) Runtime controls

During the timer:

- Press `p` to **pause/resume**.
- Press `s` to **skip** current session.
- Press `q` to **quit**.

### 4) Session flow

1. Starts a work session (`Work #1`, `Work #2`, ...).
2. Adds short breaks between most cycles.
3. After each 4th work session, uses a long break.
4. Stops after all configured work cycles complete.

### 5) Why this works well on Windows 11

- Uses `msvcrt.kbhit()` + `msvcrt.getwch()` for immediate key capture in Windows consoles.
- Uses `winsound.MessageBeep(...)` for native sound cues.
- Avoids external dependencies, so setup is simple (`python` only).
