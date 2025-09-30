# ─── PRIVACY & AUTONOMY ─────────────────────────────
set debuginfod enabled off                # Disable auto-download of debug symbols
set auto-load off                         # Prevent automatic loading of scripts from binaries

# ─── DISPLAY SETTINGS ───────────────────────────────
set print pretty on                       # Better structure for structs and arrays
set print elements 0                      # Show all elements in arrays by default

# ─── DEBUGGING QUALITY OF LIFE ──────────────────────
set history save on                       # Save history between GDB sessions
set history filename ~/.gdb_history       # Set history file path

