#!/usr/bin/env python3
"""Algorithm twin of TrackDuration + ScrubSeek + TimeFormat (Linux cannot run XCTest)."""

from __future__ import annotations

import math
import sys

PLAUSIBLE_MAX_SECONDS = 6 * 3600


def playback_seconds_from_raw(raw: float) -> float:
    if not math.isfinite(raw) or raw < 0:
        return 0.0
    if raw > PLAUSIBLE_MAX_SECONDS:
        as_ms = raw / 1000.0
        if as_ms > 0 and as_ms <= PLAUSIBLE_MAX_SECONDS:
            return as_ms
    return raw


def resolved_playback_seconds(raw: float, asset_seconds: float | None) -> float:
    known = playback_seconds_from_raw(raw)
    if known > 0:
        return known
    if asset_seconds is None:
        return 0.0
    return playback_seconds_from_raw(asset_seconds)


def format_duration(time: float) -> str:
    if not math.isfinite(time) or time < 0:
        return "--:--"
    seconds = playback_seconds_from_raw(time)
    total = int(math.trunc(seconds))
    hours = total // 3600
    minutes = (total % 3600) // 60
    secs = total % 60
    if hours > 0:
        return f"{hours}:{minutes:02d}:{secs:02d}"
    return f"{minutes}:{secs:02d}"


def scrub_command(x: float, width: float, duration: float) -> tuple[float, bool]:
    span = playback_seconds_from_raw(duration)
    if span <= 0 or not math.isfinite(width) or width <= 0 or not math.isfinite(x):
        return 0.0, False
    fraction = min(1.0, max(0.0, x / width))
    return span * fraction, True


def scrub_time(x: float, width: float, duration: float) -> float:
    return scrub_command(x, width, duration)[0]


def check(cond: bool, msg: str, failures: list[str]) -> None:
    if not cond:
        failures.append(msg)


def main() -> int:
    failures: list[str] = []
    check(abs(playback_seconds_from_raw(215) - 215) < 1e-6, "215s stays seconds", failures)
    check(abs(playback_seconds_from_raw(215_000) - 215) < 1e-6, "215000ms → 215s", failures)
    check(abs(playback_seconds_from_raw(30_000) - 30) < 1e-6, "30000ms → 30s", failures)
    check(playback_seconds_from_raw(float("nan")) == 0, "NaN duration is 0", failures)
    check(abs(playback_seconds_from_raw(3 * 3600) - 3 * 3600) < 1e-6, "3h concert stays seconds", failures)

    check(format_duration(215) == "3:35", "215s formats as 3:35", failures)
    check(format_duration(215_000) == "3:35", "millisecond ticks format as 3:35 not 59:43:20", failures)
    check(format_duration(3661) == "1:01:01", "hour formatting", failures)
    check(format_duration(0) == "0:00", "zero formats", failures)

    check(abs(scrub_time(100, 200, 180) - 90) < 1e-6, "mid-bar → half duration", failures)
    check(abs(scrub_time(80, 100, 0) - 0) < 1e-6, "zero duration does not invent 0.1s span", failures)
    check(abs(scrub_time(0.5, 1, 180) - 90) < 1e-6, "fraction maps to seconds not ms", failures)
    check(scrub_command(25, 100, 200) == (50.0, True), "seek command uses player seconds", failures)
    check(scrub_command(25, 100, 0)[1] is False, "no seek when duration unknown", failures)

    check(abs(resolved_playback_seconds(215, None) - 215) < 1e-6, "known raw skips asset", failures)
    check(abs(resolved_playback_seconds(215_000, None) - 215) < 1e-6, "known ms raw skips asset", failures)
    check(resolved_playback_seconds(0, None) == 0, "unknown raw + missing asset is 0", failures)
    check(abs(resolved_playback_seconds(0, 269.2) - 269.2) < 1e-6, "unknown raw uses asset seconds", failures)

    if failures:
        print("FAILED")
        for f in failures:
            print(" -", f)
        return 1
    print("GREEN: duration + scrub→seek mapping")
    return 0


if __name__ == "__main__":
    sys.exit(main())
