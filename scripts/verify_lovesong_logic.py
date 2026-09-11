#!/usr/bin/env python3
"""Algorithm twin of LoveSongTests (Linux cannot run xcodebuild).

Mac source of truth:
  xcodebuild test -project LuluMusic/LuluMusic.xcodeproj -scheme LoveSong \\
    -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:LoveSongTests
"""

from __future__ import annotations

from pathlib import Path
import re

ROOT = Path("/workspace")
failures: list[str] = []


def check(cond: bool, msg: str) -> None:
    if not cond:
        failures.append(msg)


def read(rel: str) -> str:
    return (ROOT / rel).read_text(encoding="utf-8")


def exists(rel: str) -> bool:
    return (ROOT / rel).exists()


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
    check("PairingCodeStore" in src, "pairing reuse store")
    tests = read("LuluMusic/LoveSongTests/PairingCodeTests.swift")
    check("testPairingRequiredBeforeUpload" in tests, "auth test")
    check("testReusesStoredPairingCodeInsteadOfRegenerating" in tests, "pairing reuse test")


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
    check("func persist(" in src, "async persist separate from send")
    tests = read("LuluMusic/LoveSongTests/DanmakuStoreAndSchedulerTests.swift")
    check("testReplaySpawnsLeadAndStaysWithin300ms" in tests, "timing test")
    check("testSendEnqueuesImmediatelyWithin100msBudget" in tests, "send test")
    check("testOptimisticSendFliesBeforeSlowPersist" in tests, "optimistic send test")
    send_fn = src.split("mutating func send(")[1].split("mutating func tick(")[0] if "mutating func send(" in src else ""
    check("store.insert" not in send_fn, "send path must not block on store.insert")


def test_wifi_policy() -> None:
    src = read("LuluMusic/LuluMusic/Core/WebImportPolicy.swift")
    check('return "http://\\(ip):\\(port)"' in src, "http://IP:port")
    check("allowsDeleteFromWeb: Bool { false }" in src, "no web delete")
    check("pageVisible && (phase == .foregroundActive || phase == .inactive)" in src, "foreground/inactive serve")
    check("listenerBindsIPv4" in src, "IPv4 bind policy")
    check("listenerAcceptLocalOnly" in src, "not localhost-only")
    check("requestsLocalNetworkAccessOnEnter" in src, "request local network")
    check("showsQRCode" in src, "QR chrome flag")
    check("stayOpenBanner" in src, "stay-open banner")
    tests = read("LuluMusic/LoveSongTests/WebImportPolicyTests.swift")
    check("testUploadRequiresAuthAndDeleteIsRejected" in tests, "wifi auth test")
    check("testMultiSelectAndAirDropAllowlist" in tests, "F01 test")
    check("testPrefersWiFiIPv4OverCellularLoopbackAndTenDotVPN" in tests, "wifi IP preference test")


def test_playback_clock_and_waveform() -> None:
    check(exists("LuluMusic/LuluMusic/Core/PlaybackClock.swift"), "PlaybackClock.swift exists")
    check(exists("LuluMusic/LuluMusic/Core/WaveformPeaks.swift"), "WaveformPeaks.swift exists")
    check(exists("LuluMusic/LuluMusic/Services/AudioWaveformAnalyzer.swift"), "AudioWaveformAnalyzer.swift exists")
    if exists("LuluMusic/LuluMusic/Core/PlaybackClock.swift"):
        clock = read("LuluMusic/LuluMusic/Core/PlaybackClock.swift")
        check("enum PlaybackClock" in clock, "PlaybackClock type")
        check("fromPlayerSeconds" in clock, "AVPlayer seconds → ms")
        check("avPlayerCurrentTime" in clock, "clock source is AVPlayer")
    clock_tests = read("LuluMusic/LoveSongTests/PlaybackClockTests.swift")
    check("testMillisecondsComeFromPlayerSecondsNotWallClock" in clock_tests, "clock test")
    if exists("LuluMusic/LuluMusic/Core/WaveformPeaks.swift"):
        peaks = read("LuluMusic/LuluMusic/Core/WaveformPeaks.swift")
        check("enum WaveformPeakSampler" in peaks, "waveform sampler")
        check("downsample" in peaks, "real peak downsample")
        check("playheadBarIndex" in peaks, "playhead sync")
    peak_tests = read("LuluMusic/LoveSongTests/WaveformPeaksTests.swift")
    check("testDownsampleUsesMaxAbsPerBucketNotTitleHash" in peak_tests, "peak test")
    check("testPlayheadBarIndexSyncsToCurrentTime" in peak_tests, "playhead test")
    check("testTimeMappedPeaksSpanFullDurationNotJustPrefix" in peak_tests, "full-duration peaks test")
    if exists("LuluMusic/LuluMusic/Services/AudioWaveformAnalyzer.swift"):
        analyzer = read("LuluMusic/LuluMusic/Services/AudioWaveformAnalyzer.swift")
        check("AVAssetReader" in analyzer, "AVAssetReader waveform")
    player = read("LuluMusic/LuluMusic/Services/PlayerEngine.swift")
    check("player?.currentTime()" in player or "player.currentTime()" in player, "live AVPlayer currentTime")
    check("PlaybackClock.milliseconds" in player, "engine uses PlaybackClock")
    chrome = read("LuluMusic/LuluMusic/Views/PlayerChrome.swift")
    check("Hasher()" not in chrome, "no hashed fake waveform")
    check("peaks" in chrome, "scrubber takes real peaks")
    composer = chrome.split("struct GlassDanmakuComposer")[1] if "struct GlassDanmakuComposer" in chrome else ""
    check("DragGesture" not in composer, "fixed danmaku bar, no drag")


def test_wifi_ui_and_plist() -> None:
    view = read("LuluMusic/LuluMusic/Views/WebUploadView.swift")
    check("QRCode" not in view and "qrCard" not in view, "QR UI removed")
    check("L10n.startServer" not in view and "L10n.stopServer" not in view, "no Start/Stop UI")
    check("LocalNetworkAccess" in view, "request local network on enter")
    check("stayOpenBanner" in view or "上传时请保持本页打开" in view, "stay-open banner in UI")
    l10n = read("LuluMusic/LuluMusic/Theme/L10n.swift")
    check("演唱会回忆" in l10n, "rename 曲库 → 演唱会回忆")
    check("曲库" not in l10n, "no leftover 曲库 in L10n")
    plist = read("LuluMusic/LuluMusic/Info.plist")
    check("NSLocalNetworkUsageDescription" in plist, "local network usage")
    check("NSBonjourServices" in plist, "Bonjour services")
    check("NSAllowsLocalNetworking" in plist, "ATS local networking")
    check("_lovesong._tcp" in plist, "LoveSong Bonjour type")
    server = read("LuluMusic/LuluMusic/Services/WebUploadServer.swift")
    check("acceptLocalOnly = LANBindPolicy.listenerAcceptLocalOnly" in server or "acceptLocalOnly = false" in server, "listener not localhost-only")
    check("includePeerToPeer = LANBindPolicy.listenerIncludePeerToPeer" in server or "includePeerToPeer = true" in server, "peer-to-peer LAN")
    check("version = .v4" in server, "force IPv4")
    check("NWListener.Service" in server, "Bonjour advertise")
    check("PairingCodeStore.loadOrCreate" in server, "reuse pairing code")
    check("QRCodeImage.swift" not in read("scripts/generate_xcodeproj.py"), "QR file dropped from project")


def test_matched_geometry_single_source() -> None:
    chrome = read("LuluMusic/LuluMusic/Views/PlayerChrome.swift")
    mini = read("LuluMusic/LuluMusic/Views/MiniPlayerBar.swift")
    player = read("LuluMusic/LuluMusic/Views/PlayerView.swift")
    content = read("LuluMusic/LuluMusic/ContentView.swift")
    tests = read("LuluMusic/LoveSongTests/NowPlayingMatchedGeometryTests.swift")
    check("enum NowPlayingMatchedGeometry" in chrome, "exclusive-source helper")
    check("case .miniPlayer, .playerTab:" in chrome, "collapsed surfaces share !presented")
    check("return !isFullPlayerPresented" in chrome, "mini/tab isSource: !isFullPlayerPresented")
    check("static func isSource(" in chrome, "isSource gate")
    check("static func participates(" in chrome, "participates gate")
    check("var isActive: Bool" in chrome, "matchedGeometry can leave the group")
    check("NowPlayingMatchedGeometry.isSource" in mini, "mini uses shared isSource")
    check("NowPlayingMatchedGeometry.participates" in mini, "mini uses participates")
    check("NowPlayingMatchedGeometry.isSource" in player, "player uses shared isSource")
    check("NowPlayingMatchedGeometry.participates" in player, "player uses participates")
    check("NowPlayingCoverMatch(isSource:" in mini and "isActive:" in mini, "mini cover isActive")
    check("NowPlayingPlayMatch(isSource:" in mini and "isActive:" in mini, "mini play isActive")
    check("playMatchActive:" in player, "full player play match gated")
    check("NowPlayingCoverMatch(isSource:" in player and "isActive:" in player, "player cover isActive")
    check("testAtMostOneSourceForEveryPresentationState" in tests, "exclusivity XCTest")
    check("testMiniStaysInGroupWhileFullPlayerPresents" in tests, "transition XCTest")
    # Mini bar must stay mounted while the overlay is up so isSource can flip to false.
    check(
        re.search(r"!player\.isFullPlayerPresented[\s\S]{0,80}MiniPlayerBar", content) is None,
        "mini bar must stay mounted during full player (do not unmount on isFullPlayerPresented)",
    )
    # Logic twin of NowPlayingMatchedGeometry.isSource — at most one source in every state.
    for tab in ("library", "player"):
        for presented in (False, True):
            sources = [
                surface
                for surface in ("miniPlayer", "playerTab", "fullPlayer")
                if _matched_geometry_is_source(surface, tab, presented)
            ]
            check(
                len(sources) <= 1,
                f"logic twin dual source tab={tab} presented={presented} sources={sources}",
            )
    check(_matched_geometry_is_source("miniPlayer", "library", False), "mini source when collapsed")
    check(not _matched_geometry_is_source("miniPlayer", "library", True), "mini not source when presented")
    check(_matched_geometry_is_source("fullPlayer", "library", True), "full source when presented")
    check(_matched_geometry_is_source("fullPlayer", "player", True), "full source from player tab")
    check(not _matched_geometry_is_source("playerTab", "player", True), "player tab yields while presented")


def _matched_geometry_is_source(surface: str, tab: str, presented: bool) -> bool:
    participates = (
        (surface == "miniPlayer" and tab == "library")
        or (surface == "playerTab" and tab == "player")
        or (surface == "fullPlayer" and presented)
    )
    if not participates:
        return False
    if surface in ("miniPlayer", "playerTab"):
        return not presented
    return True


def test_project_wires_tests() -> None:
    pbx = read("LuluMusic/LuluMusic.xcodeproj/project.pbxproj")
    check("LoveSongTests" in pbx, "test target")
    check("NowPlayingMatchedGeometryTests" in pbx, "geometry XCTest in pbx")
    check("DanmakuCore.swift" in pbx, "core in pbx")
    check("LoveSongTheme.swift" in pbx, "concert theme tokens in pbx")
    check("StageComponents.swift" in pbx, "shared stage chrome in pbx")
    check("PlayerChrome.swift" in pbx, "shared player chrome in pbx")
    check("CoverPalette.swift" in pbx, "cover atmosphere helper in pbx")
    check("PlaybackClock.swift" in pbx, "PlaybackClock in pbx")
    check("WaveformPeaks.swift" in pbx, "WaveformPeaks in pbx")
    check("AudioWaveformAnalyzer.swift" in pbx, "waveform analyzer in pbx")
    check("LocalNetworkAccess.swift" in pbx, "local network prompt in pbx")
    check("PlaybackClockTests.swift" in pbx, "clock tests in pbx")
    check("WaveformPeaksTests.swift" in pbx, "peak tests in pbx")
    check("QRCodeImage.swift" not in pbx, "QR removed from pbx")
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
        test_playback_clock_and_waveform,
        test_wifi_ui_and_plist,
        test_matched_geometry_single_source,
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
