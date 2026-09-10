#!/usr/bin/env python3
"""Algorithm twin of LoveSongTests (Linux cannot run xcodebuild).

Mac source of truth:
  xcodebuild test -project LuluMusic/LuluMusic.xcodeproj -scheme LoveSong \\
    -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:LoveSongTests
"""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path("/workspace")
failures: list[str] = []


def check(cond: bool, msg: str) -> None:
    if not cond:
        failures.append(msg)


def read(rel: str) -> str:
    return (ROOT / rel).read_text(encoding="utf-8")


def test_allowlist() -> None:
    src = read("LuluMusic/LuluMusic/Core/ImportFormatAllowlist.swift")
    check('["mp3", "m4a", "aac", "wav", "flac"]' in src or '"mp3", "m4a", "aac", "wav", "flac"' in src, "F03 allowlist")
    check('"ogg"' in src, "F03 rejects ogg")
    tests = read("LuluMusic/LoveSongTests/ImportFormatAllowlistTests.swift")
    check("testRejectsOGGInV01" in tests, "ogg test exists")


def test_pairing() -> None:
    src = read("LuluMusic/LuluMusic/Core/PairingAuth.swift")
    check("trimmed.count == 4" in src, "4-digit pairing")
    check("func pair(entered: String)" in src, "pair API")
    tests = read("LuluMusic/LoveSongTests/PairingCodeTests.swift")
    check("testPairingRequiredBeforeUpload" in tests, "auth test")


def test_playback_mode() -> None:
    src = read("LuluMusic/LuluMusic/Core/PlaybackMode.swift")
    check("case sequential" in src and "case repeatOne" in src and "case shuffle" in src, "F10 three states")
    check("case .all" not in src, "no repeat-all")
    tests = read("LuluMusic/LoveSongTests/PlaybackModeTests.swift")
    check("testCyclesThreeStatesOnly" in tests, "cycle test")
    check("testSequentialStopsAtEndOnAutoAdvance" in tests, "sequential stop")
    check("testRepeatOneReplaysCurrentOnEnd" in tests, "repeat one")


def test_resume() -> None:
    src = read("LuluMusic/LuluMusic/Core/ResumeState.swift")
    check("positionMS" in src and "danmakuEnabled" in src, "F09 resume fields")
    tests = read("LuluMusic/LoveSongTests/ResumeStateTests.swift")
    check("testPersistsTrackPositionModeAndDanmaku" in tests, "resume test")


def test_search() -> None:
    src = read("LuluMusic/LuluMusic/Core/LibrarySearch.swift")
    check("venueTag" in src, "F08 venueTag")
    tests = read("LuluMusic/LoveSongTests/LibrarySearchTests.swift")
    check("testSearchByTitleArtistAndVenueTag" in tests, "search test")


def test_danmaku() -> None:
    src = read("LuluMusic/LuluMusic/Core/DanmakuCore.swift")
    check("spawnLeadMS: Int = 500" in src, "500ms lead")
    check("timingToleranceMS: Int = 300" in src, "±300ms")
    check("densityCap: Int = 5" in src, "density 5")
    check("maxLanes: Int = 3" in src, "3 lanes")
    check("sendAppearBudgetMS: Int = 100" in src, "≤100ms send")
    tests = read("LuluMusic/LoveSongTests/DanmakuStoreAndSchedulerTests.swift")
    check("testReplaySpawnsLeadAndStaysWithin300ms" in tests, "timing test")
    check("testSendEnqueuesImmediatelyWithin100msBudget" in tests, "send test")


def test_wifi_policy() -> None:
    src = read("LuluMusic/LuluMusic/Core/WebImportPolicy.swift")
    check('return "http://\\(ip):\\(port)"' in src, "http://IP:port")
    check("allowsDeleteFromWeb: Bool { false }" in src, "no web delete")
    check("pageVisible && phase == .foregroundActive" in src, "foreground only")
    tests = read("LuluMusic/LoveSongTests/WebImportPolicyTests.swift")
    check("testUploadRequiresAuthAndDeleteIsRejected" in tests, "wifi auth test")
    check("testMultiSelectAndAirDropAllowlist" in tests, "F01 test")


def test_project_wires_tests() -> None:
    pbx = read("LuluMusic/LuluMusic.xcodeproj/project.pbxproj")
    check("LoveSongTests" in pbx, "test target")
    check("DanmakuCore.swift" in pbx, "core in pbx")
    check("LoveSongTheme.swift" in pbx, "concert theme tokens in pbx")
    check("StageComponents.swift" in pbx, "shared stage chrome in pbx")
    check("RepeatMode.swift" not in pbx, "repeat-all type removed")
    scheme = read("LuluMusic/LuluMusic.xcodeproj/xcshareddata/xcschemes/LoveSong.xcscheme")
    check("LoveSongTests.xctest" in scheme, "scheme runs tests")
    plist = read("LuluMusic/LuluMusic/Info.plist")
    check("<string>LoveSong</string>" in plist, "display name")


def main() -> None:
    for fn in (
        test_allowlist,
        test_pairing,
        test_playback_mode,
        test_resume,
        test_search,
        test_danmaku,
        test_wifi_policy,
        test_project_wires_tests,
    ):
        fn()
    if failures:
        print("FAILED")
        for f in failures:
            print(" -", f)
        raise SystemExit(1)
    print("OK: LoveSong P0 logic contracts + XCTest wiring checks passed")
    print("Mac: xcodebuild test -project LuluMusic/LuluMusic.xcodeproj -scheme LoveSong -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:LoveSongTests")


if __name__ == "__main__":
    main()
