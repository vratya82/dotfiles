#!/usr/bin/env python3
"""A Windows-friendly CLI Pomodoro timer with keyboard controls.

Controls while timer runs:
  p = pause/resume
  s = skip current session
  q = quit timer
"""

from __future__ import annotations

import argparse
import os
import sys
import time
from dataclasses import dataclass


@dataclass
class SessionConfig:
    work_minutes: int
    short_break_minutes: int
    long_break_minutes: int
    cycles: int


class KeyReader:
    """Reads single-key input without requiring Enter."""

    def __init__(self) -> None:
        self._is_windows = os.name == "nt"
        if self._is_windows:
            import msvcrt  # type: ignore

            self._msvcrt = msvcrt
        else:
            import select

            self._select = select

    def read_key(self) -> str | None:
        if self._is_windows:
            if self._msvcrt.kbhit():
                return self._msvcrt.getwch().lower()
            return None

        ready, _, _ = self._select.select([sys.stdin], [], [], 0)
        if ready:
            return sys.stdin.read(1).lower()
        return None


class PomodoroTimer:
    def __init__(self, config: SessionConfig) -> None:
        self.config = config
        self.key_reader = KeyReader()
        self.paused = False

    def run(self) -> int:
        self._print_header()

        for cycle in range(1, self.config.cycles + 1):
            if not self._run_session(self.config.work_minutes * 60, f"Work #{cycle}"):
                return 1

            is_last_cycle = cycle == self.config.cycles
            if is_last_cycle:
                break

            if cycle % 4 == 0:
                label = f"Long Break after cycle {cycle}"
                minutes = self.config.long_break_minutes
            else:
                label = f"Short Break after cycle {cycle}"
                minutes = self.config.short_break_minutes

            if not self._run_session(minutes * 60, label):
                return 1

        print("\n✅ Pomodoro plan finished. Great work!")
        return 0

    def _run_session(self, total_seconds: int, label: str) -> bool:
        print(f"\n--- {label} ({total_seconds // 60} min) ---")
        self._notify(label)
        remaining = total_seconds

        while remaining >= 0:
            key = self.key_reader.read_key()
            if key:
                result = self._handle_key(key)
                if result == "quit":
                    print("\nTimer stopped by user.")
                    return False
                if result == "skip":
                    print(f"\nSkipped: {label}")
                    return True

            self._render_time(label, remaining)

            if remaining == 0:
                break

            if not self.paused:
                remaining -= 1
            time.sleep(1)

        self._notify(f"Done: {label}")
        print()
        return True

    def _handle_key(self, key: str) -> str | None:
        if key == "p":
            self.paused = not self.paused
            state = "paused" if self.paused else "resumed"
            print(f"\n[{state}]", end=" ", flush=True)
            return "pause"
        if key == "s":
            return "skip"
        if key == "q":
            return "quit"
        return None

    def _render_time(self, label: str, remaining: int) -> None:
        minutes, seconds = divmod(remaining, 60)
        status = "PAUSED" if self.paused else "RUNNING"
        line = f"\r{label:<28} {minutes:02d}:{seconds:02d} [{status}]"
        print(line, end="", flush=True)

    def _notify(self, message: str) -> None:
        print(f"\n🔔 {message}")
        if os.name == "nt":
            try:
                import winsound  # type: ignore

                winsound.MessageBeep(winsound.MB_ICONASTERISK)
            except Exception:
                pass
        else:
            print("\a", end="", flush=True)

    @staticmethod
    def _print_header() -> None:
        print("Pomodoro Timer (CLI)")
        print("Controls: [p]ause/resume, [s]kip, [q]uit")


def positive_int(value: str) -> int:
    number = int(value)
    if number <= 0:
        raise argparse.ArgumentTypeError("Value must be greater than 0")
    return number


def parse_args() -> SessionConfig:
    parser = argparse.ArgumentParser(
        description="Pomodoro CLI timer (works well in Windows 11 terminals)."
    )
    parser.add_argument("--work", type=positive_int, default=25, help="Work length in minutes")
    parser.add_argument(
        "--short-break",
        type=positive_int,
        default=5,
        help="Short break length in minutes",
    )
    parser.add_argument(
        "--long-break",
        type=positive_int,
        default=15,
        help="Long break length in minutes",
    )
    parser.add_argument(
        "--cycles",
        type=positive_int,
        default=4,
        help="Number of work sessions to run",
    )
    args = parser.parse_args()

    return SessionConfig(
        work_minutes=args.work,
        short_break_minutes=args.short_break,
        long_break_minutes=args.long_break,
        cycles=args.cycles,
    )


def main() -> int:
    config = parse_args()
    timer = PomodoroTimer(config)
    return timer.run()


if __name__ == "__main__":
    raise SystemExit(main())
