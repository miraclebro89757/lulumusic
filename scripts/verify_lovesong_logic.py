#!/usr/bin/env python3
"""Algorithm twin of LoveSongTests (Linux cannot run xcodebuild).

Mac source of truth:
  xcodebuild test -project LuluMusic/LuluMusic.xcodeproj -scheme LoveSong \\
    -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:LoveSongTests
"""

from __future__ import annotations

from pathlib import Path

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
    check("testSendWhenDisplayOffStillReturnsRecordWithoutFlying" in tests, "display-off still writes")
    check("testSendTruncatesToEightyCharacters" in tests, "80-char truncate test")
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
    check("isSeeking" in player, "seek suppresses playhead observer")
    check("seekGeneration" in player, "overlapping scrub seeks")
    check("player.seek(to: cm" in player or "player?.seek(to: cm" in player, "AVPlayer.seek")
    check("AVURLAssetPreferPreciseDurationAndTimingKey" in player or "TrackDuration.preciseAsset" in player, "precise item duration")
    chrome = read("LuluMusic/LuluMusic/Views/PlayerChrome.swift")
    check("Hasher()" not in chrome, "no hashed fake waveform")
    check("peaks" in chrome, "scrubber takes real peaks")
    check("highPriorityGesture" in chrome, "scrubber wins over tab swipe")
    check("ScrubSeek.command" in chrome, "scrub maps to seek seconds")
    drag = chrome.split("private func drag")[1].split("struct MiniProgressHint")[0] if "private func drag" in chrome else ""
    check("onChanged" in drag and "onSeek" in drag, "dragging calls onSeek")
    check("onEnded" in drag and "onSeek" in drag, "release calls onSeek")
    check("max(duration, 0.1)" not in chrome, "no fake 0.1s duration span")
    composer = chrome.split("struct GlassDanmakuComposer")[1] if "struct GlassDanmakuComposer" in chrome else ""
    check("DragGesture" not in composer, "fixed danmaku bar, no drag")
    meta = read("LuluMusic/LuluMusic/Services/MetadataExtractor.swift")
    check("TrackDuration.preciseAsset" in meta, "import uses precise AVURLAsset")
    check("TrackDuration.playbackSeconds" in meta, "import stores seconds")
    check("id3MetadataLength" in meta, "TLEN milliseconds fallback")
    player_view = read("LuluMusic/LuluMusic/Views/PlayerView.swift")
    check("player.seek(to:" in player_view, "waveform scrubber wired to PlayerEngine.seek")
    duration_src = read("LuluMusic/LuluMusic/Core/TrackDuration.swift")
    check("plausibleMaxSeconds" in duration_src, "ms vs seconds heuristic")
    check("AVURLAssetPreferPreciseDurationAndTimingKey" in duration_src, "precise duration option")
    check("static func resolvedPlaybackSeconds" in duration_src, "async import duration helper")
    check("await asset.load(.duration)" in duration_src, "helper awaits asset.load(.duration)")
    library = read("LuluMusic/LuluMusic/Services/LibraryService.swift")
    check("TrackDuration.resolvedPlaybackSeconds" in library, "import paths use duration helper")
    check("duration: {" not in library, "no sync duration IIFE in LibraryService")
    check("try? await asset.load(.duration)" not in library, "no await inside LibraryService closures")
    import_media = library.split("private func importMediaItem")[1].split("private func exportAsset")[0] if "private func importMediaItem" in library else ""
    check("let resolvedDuration = await TrackDuration.resolvedPlaybackSeconds" in import_media, "importMediaItem awaits duration before Track()")
    import_file = library.split("func importFile(")[1].split("func importFiles(")[0] if "func importFile(" in library else ""
    check("let resolvedDuration = await TrackDuration.resolvedPlaybackSeconds" in import_file, "importFile awaits duration before Track()")
    scrub_src = read("LuluMusic/LuluMusic/Core/ScrubSeek.swift")
    check("shouldSeek" in scrub_src, "scrub command")
    duration_tests = read("LuluMusic/LoveSongTests/TrackDurationTests.swift")
    check("testTreatsImplausibleHourLongValuesAsMilliseconds" in duration_tests, "duration unit test")
    check("testDisplayFormatsSecondsNotMillisecondTicks" in duration_tests, "TimeFormat test")
    check("testResolvedPlaybackSecondsKeepsKnownRawWithoutReadingFile" in duration_tests, "resolved duration known-raw test")
    check("testResolvedPlaybackSecondsReturnsZeroWhenRawUnknownAndAssetMissing" in duration_tests, "resolved duration missing-asset test")
    scrub_tests = read("LuluMusic/LoveSongTests/ScrubSeekTests.swift")
    check("testMapsBarFractionOntoDurationSeconds" in scrub_tests, "scrub mapping test")
    check("testZeroDurationDoesNotInventATenthSecondSpan" in scrub_tests, "no fake span test")
    check("testSeekCommandUsesPlayerSeconds" in scrub_tests, "seek command test")


def test_wifi_ui_and_plist() -> None:
    view = read("LuluMusic/LuluMusic/Views/WebUploadView.swift")
    check("QRCode" not in view and "qrCard" not in view, "QR UI removed")
    check("L10n.startServer" not in view and "L10n.stopServer" not in view, "no Start/Stop UI")
    check("LocalNetworkAccess" in view, "request local network on enter")
    check("stayOpenBanner" in view or "上传时请保持本页打开" in view, "stay-open banner in UI")
    l10n = read("LuluMusic/LuluMusic/Theme/L10n.swift")
    check("我的歌单" in l10n, "playlist title 我的歌单")
    check("歌单" in l10n and "现场弹幕" in l10n and "播放器" in l10n, "tab copy 播放器 / 现场弹幕 / 歌单")
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


def test_no_now_playing_matched_geometry() -> None:
    """Shared-element morph stays gone; MiniPlayer switches Player Tab (no overlay)."""
    chrome = read("LuluMusic/LuluMusic/Views/PlayerChrome.swift")
    mini = read("LuluMusic/LuluMusic/Views/MiniPlayerBar.swift")
    player = read("LuluMusic/LuluMusic/Views/PlayerView.swift")
    content = read("LuluMusic/LuluMusic/ContentView.swift")
    generator = read("scripts/generate_xcodeproj.py")
    swift_files = list((ROOT / "LuluMusic").rglob("*.swift"))
    for path in swift_files:
        src = path.read_text(encoding="utf-8")
        check("matchedGeometryEffect" not in src, f"no matchedGeometryEffect in {path.relative_to(ROOT)}")
        check("nowPlayingCover" not in src, f"no nowPlayingCover id in {path.relative_to(ROOT)}")
        check("nowPlayingPlay" not in src, f"no nowPlayingPlay id in {path.relative_to(ROOT)}")
        check("NowPlayingMatchedGeometry" not in src, f"no NowPlayingMatchedGeometry in {path.relative_to(ROOT)}")
        check("NowPlayingCoverMatch" not in src, f"no NowPlayingCoverMatch in {path.relative_to(ROOT)}")
        check("NowPlayingPlayMatch" not in src, f"no NowPlayingPlayMatch in {path.relative_to(ROOT)}")
        check("NowPlayingMatchSurface" not in src, f"no NowPlayingMatchSurface in {path.relative_to(ROOT)}")
        check("concertNamespace" not in src, f"no concertNamespace in {path.relative_to(ROOT)}")
    check(not exists("LuluMusic/LoveSongTests/NowPlayingMatchedGeometryTests.swift"), "geometry XCTest removed")
    check("NowPlayingMatchedGeometryTests" not in generator, "geometry XCTest dropped from project generator")
    check("playIsSource" not in chrome and "playMatchActive" not in chrome, "transport has no match source flags")
    check("struct MiniPlayerBar" in mini, "mini player bar intact")
    check("FullPlayerOverlay" not in content, "no FullPlayerOverlay on root (CH-14)")
    check("isFullPlayerPresented" not in content, "overlay present flag removed from root")
    check("struct PlayerView" in player, "full player view intact")
    check("@Namespace" not in content, "no shared-element namespace on root")
    check("isFullPlayerPresented" not in mini, "MiniPlayer does not morph overlay")


def test_project_wires_tests() -> None:
    pbx = read("LuluMusic/LuluMusic.xcodeproj/project.pbxproj")
    check("LoveSongTests" in pbx, "test target")
    check("NowPlayingMatchedGeometryTests" not in pbx, "geometry XCTest removed from pbx")
    check("DanmakuCore.swift" in pbx, "core in pbx")
    check("LoveSongTheme.swift" in pbx, "concert theme tokens in pbx")
    check("StageComponents.swift" in pbx, "shared stage chrome in pbx")
    check("PlayerChrome.swift" in pbx, "shared player chrome in pbx")
    check("CoverPalette.swift" in pbx, "cover atmosphere helper in pbx")
    check("PlaybackClock.swift" in pbx, "PlaybackClock in pbx")
    check("TrackDuration.swift" in pbx, "TrackDuration in pbx")
    check("ScrubSeek.swift" in pbx, "ScrubSeek in pbx")
    check("WaveformPeaks.swift" in pbx, "WaveformPeaks in pbx")
    check("AudioWaveformAnalyzer.swift" in pbx, "waveform analyzer in pbx")
    check("LocalNetworkAccess.swift" in pbx, "local network prompt in pbx")
    check("PlaybackClockTests.swift" in pbx, "clock tests in pbx")
    check("WaveformPeaksTests.swift" in pbx, "peak tests in pbx")
    check("TrackDurationTests.swift" in pbx, "duration tests in pbx")
    check("ScrubSeekTests.swift" in pbx, "scrub tests in pbx")
    check("QRCodeImage.swift" not in pbx, "QR removed from pbx")
    check("RepeatMode.swift" not in pbx, "repeat-all type removed")
    check("LiveDanmakuWindow.swift" in pbx, "Live visible-window helper in pbx")
    check("LiveView.swift" in pbx, "LiveView in pbx")
    check("PlaylistView.swift" in pbx, "PlaylistView in pbx")
    check("DanmakuModal.swift" in pbx, "DanmakuModal in pbx")
    check("LoveSongTabBar.swift" in pbx, "custom tab bar in pbx")
    check("FavoriteStore.swift" in pbx, "FavoriteStore in pbx")
    check("ConcertDateFormat.swift" in pbx, "ConcertDateFormat in pbx")
    check("LocalDanmakuIdentity.swift" in pbx, "LocalDanmakuIdentity in pbx")
    check("DanmakuPhrasePack.swift" in pbx, "DanmakuPhrasePack in pbx")
    check("FavoriteStoreTests.swift" in pbx, "favorite XCTest in pbx")
    check("PixelChromeTests.swift" in pbx, "pixel chrome XCTest in pbx")
    check("LiveDanmakuWindowTests.swift" in pbx, "Live window tests in pbx")
    check("LibraryView.swift" not in pbx, "LibraryView renamed to PlaylistView")
    check("DEVELOPMENT_TEAM = 5595Y4TR6U;" in pbx, "keep DEVELOPMENT_TEAM 5595Y4TR6U")
    generator = read("scripts/generate_xcodeproj.py")
    check("DEVELOPMENT_TEAM = 5595Y4TR6U;" in generator, "generator keeps DEVELOPMENT_TEAM")
    yml = read("LuluMusic/project.yml")
    check("DEVELOPMENT_TEAM: 5595Y4TR6U" in yml, "project.yml keeps DEVELOPMENT_TEAM")
    scheme = read("LuluMusic/LuluMusic.xcodeproj/xcshareddata/xcschemes/LoveSong.xcscheme")
    check("LoveSongTests.xctest" in scheme, "scheme runs tests")
    plist = read("LuluMusic/LuluMusic/Info.plist")
    check("<string>LoveSong</string>" in plist, "display name")


def live_visible_python(records: list[dict], now_ms: int, limit: int = 50) -> list[dict]:
    triggered = [r for r in records if r["timestampMS"] <= now_ms]
    triggered.sort(key=lambda r: (r["timestampMS"], r["createdAt"], r["id"]))
    return triggered[-limit:] if len(triggered) > limit else triggered


def test_live_visible_window() -> None:
    check(exists("LuluMusic/LuluMusic/Core/LiveDanmakuWindow.swift"), "LiveDanmakuWindow.swift exists")
    check(exists("LuluMusic/LoveSongTests/LiveDanmakuWindowTests.swift"), "LiveDanmakuWindow XCTest exists")
    src = read("LuluMusic/LuluMusic/Core/LiveDanmakuWindow.swift") if exists("LuluMusic/LuluMusic/Core/LiveDanmakuWindow.swift") else ""
    tests = read("LuluMusic/LoveSongTests/LiveDanmakuWindowTests.swift")
    check("enum LiveDanmakuWindow" in src or "struct LiveDanmakuWindow" in src, "LiveDanmakuWindow type")
    check("maxVisible" in src and "50" in src, "visible cap 50")
    check("timestampMS" in src and "<=" in src, "only timestampMS ≤ now")
    check("suffix(" in src or "suffix (" in src, "keep last N triggered")
    check("testIncludesOnlyCommentsAtOrBeforeNow" in tests, "≤ now test")
    check("testCapsVisibleSetAtFiftyMostRecentTriggered" in tests, "cap 50 test")
    check("testSeekBackwardRebuildsWindowFromScratch" in tests, "seek rebuild test")
    records = [
        {"id": f"{i:03d}", "timestampMS": i * 100, "createdAt": i, "text": f"c{i}"}
        for i in range(80)
    ]
    now = live_visible_python(records, now_ms=10_000)
    check(len(now) == 50, "python twin caps at 50")
    check(now[0]["text"] == "c30" and now[-1]["text"] == "c79", "python twin keeps last 50")
    future_excluded = live_visible_python(
        [
            {"id": "a", "timestampMS": 1000, "createdAt": 0, "text": "early"},
            {"id": "b", "timestampMS": 5000, "createdAt": 0, "text": "now"},
            {"id": "c", "timestampMS": 9000, "createdAt": 0, "text": "future"},
        ],
        now_ms=5000,
    )
    check([r["text"] for r in future_excluded] == ["early", "now"], "python twin excludes future")
    after_seek = live_visible_python(records[:10], now_ms=200)
    check([r["text"] for r in after_seek] == ["c0", "c1", "c2"], "python twin seek rebuild")
    live = read("LuluMusic/LuluMusic/Views/LiveView.swift") if exists("LuluMusic/LuluMusic/Views/LiveView.swift") else ""
    check("LiveDanmakuWindow" in live, "LiveView uses LiveDanmakuWindow")
    check("DanmakuService" in live, "LiveView shares DanmakuService")
    check("PlayerEngine" in live, "LiveView shares PlayerEngine")
    check("heart.fill" not in live and "FloatingHeart" not in live, "Live has no floating hearts")
    check("LikeButton" not in live, "Live has no LikeButton type")
    check("AvatarStack" not in live, "Live has no AvatarStack")
    check("DanmakuAvatarBubble" in live, "Live uses avatar+name bubble chrome")
    check('LocalDanmakuIdentity.displayName' in live or '"我"' in live, "Live identity is 我")


def test_theme_black_purple_white() -> None:
    theme = read("LuluMusic/LuluMusic/Theme/LoveSongTheme.swift")
    check("0x09060F" in theme, "bg.stage #09060F")
    check("0x0E0A17" in theme, "bg.elevated #0E0A17")
    check("0x8B5CF6" in theme, "accent #8B5CF6")
    check("0x7C3AED" in theme, "accentPressed #7C3AED")
    check("static let accent" in theme, "accent token name")
    check("0xFF8A3D" not in theme, "theme has no #FF8A3D")
    check("spotlight" not in theme or "static let spotlight" not in theme, "spotlight orange token removed")
    accent_asset = read("LuluMusic/LuluMusic/Assets.xcassets/AccentColor.colorset/Contents.json")
    check('"red" : "1.000"' not in accent_asset, "AccentColor is not leftover orange")
    check("0.545" in accent_asset or "0.545098" in accent_asset or '"red" : "0.545"' in accent_asset, "AccentColor red ~8B")
    orange_hits = []
    for path in (ROOT / "LuluMusic").rglob("*"):
        if not path.is_file() or path.suffix.lower() not in {".swift", ".json"}:
            continue
        text = path.read_text(encoding="utf-8", errors="ignore")
        if "FF8A3D" in text or "0xFF8A3D" in text:
            orange_hits.append(str(path.relative_to(ROOT)))
    check(orange_hits == [], f"FF8A3D leftover as primary accent: {orange_hits}")
    content = read("LuluMusic/LuluMusic/ContentView.swift")
    check(".tint(LoveSongTheme.accent)" in content, "Tab tint is accent purple")


def test_three_tab_ia() -> None:
    content = read("LuluMusic/LuluMusic/ContentView.swift")
    chrome = read("LuluMusic/LuluMusic/Views/PlayerChrome.swift")
    l10n = read("LuluMusic/LuluMusic/Theme/L10n.swift")
    check("case playlist" in chrome and "case player" in chrome and "case live" in chrome, "AppTab has playlist/player/live")
    check("case library" not in chrome, "AppTab.library removed")
    check("PlaylistView" in content, "Playlist tab content")
    check("PlayerView" in content, "Player tab content")
    check("LiveView" in content, "Live tab content")
    check("opticaldisc" in content or "AppTab.player.systemImage" in content, "player SF opticaldisc")
    check("bubble.left.and.bubble.right" in content or "AppTab.live.systemImage" in content, "live SF bubble")
    check("music.note.list" in content or "AppTab.playlist.systemImage" in content, "playlist SF music.note.list")
    check("tabPlaylist" in l10n and "tabPlayer" in l10n and "tabLive" in l10n, "three tab L10n keys")
    check('static let tabPlayer = "播放器"' in l10n, "tab.player 播放器")
    check('static let tabLive = "现场弹幕"' in l10n, "tab.live 现场弹幕")
    check('static let tabPlaylist = "歌单"' in l10n, "tab.playlist 歌单")
    check("ConcertMemory" not in content and "Setlist" not in content, "no ConcertMemory/Setlist in root")
    player = read("LuluMusic/LuluMusic/Views/PlayerView.swift")
    check("tab = .live" in player, "Player cover/venue switches to Live Tab")
    check("tab = .playlist" in player, "Player ⋮ switches to Playlist Tab")
    check("GlassDanmakuComposer" not in player, "Player has no persistent danmaku input")
    check("toggleLike" in player or "LikeHeartButton" in player, "Player has local heart")
    playlist = read("LuluMusic/LuluMusic/Views/PlaylistView.swift") if exists("LuluMusic/LuluMusic/Views/PlaylistView.swift") else ""
    check("tab = .player" in playlist, "Playlist return/row play switches to Player Tab")
    check("WebUploadView" in playlist, "Wi-Fi entry from Playlist")
    check("playlistReturn" in playlist or "返回当前播放" in playlist, "返回当前播放")
    wifi = read("LuluMusic/LuluMusic/Views/WebUploadView.swift")
    check("LoveSongTheme.accent" in wifi, "Wi-Fi restyle uses accent token")
    modal = read("LuluMusic/LuluMusic/Views/DanmakuModal.swift") if exists("LuluMusic/LuluMusic/Views/DanmakuModal.swift") else ""
    phrases = read("LuluMusic/LuluMusic/Core/DanmakuPhrasePack.swift") if exists("LuluMusic/LuluMusic/Core/DanmakuPhrasePack.swift") else ""
    pack = modal + phrases
    check("现场封神" in pack, "S5 chip 现场封神")
    check("万人大合唱" in pack, "S5 chip 万人大合唱")
    check("这首直接泪目" in pack, "S5 chip 这首直接泪目")
    check("永远的经典" in pack, "S5 chip 永远的经典")
    check("DanmakuPhrasePack.featured" in modal, "Modal uses featured phrase pack")
    drop_needles = ("struct LikeButton", "FloatingHeart", "AvatarStack", "ConcertMemoryModal", "SetlistDrawer")
    for path in (ROOT / "LuluMusic").rglob("*.swift"):
        src = path.read_text(encoding="utf-8")
        for needle in drop_needles:
            check(needle not in src, f"{needle} must not appear in {path.relative_to(ROOT)}")


def test_pixel_1to1() -> None:
    player = read("LuluMusic/LuluMusic/Views/PlayerView.swift")
    live = read("LuluMusic/LuluMusic/Views/LiveView.swift")
    modal = read("LuluMusic/LuluMusic/Views/DanmakuModal.swift")
    playlist = read("LuluMusic/LuluMusic/Views/PlaylistView.swift")
    chrome = read("LuluMusic/LuluMusic/Views/PlayerChrome.swift")
    tabbar = read("LuluMusic/LuluMusic/Views/LoveSongTabBar.swift")
    content = read("LuluMusic/LuluMusic/ContentView.swift")
    l10n = read("LuluMusic/LuluMusic/Theme/L10n.swift")
    favorites = read("LuluMusic/LuluMusic/Core/FavoriteStore.swift")
    identity = read("LuluMusic/LuluMusic/Core/LocalDanmakuIdentity.swift")
    phrases = read("LuluMusic/LuluMusic/Core/DanmakuPhrasePack.swift")
    artwork = read("LuluMusic/LuluMusic/Views/ArtworkView.swift")
    venue = read("LuluMusic/LuluMusic/Views/StageComponents.swift")
    app = read("LuluMusic/LuluMusic/LuluMusicApp.swift")

    check("case player" in chrome and chrome.find("case player") < chrome.find("case live") < chrome.find("case playlist"), "AppTab case order player/live/playlist")
    check("AppTab.allCases" in tabbar, "custom tab iterates allCases")
    check("Capsule()" in tabbar, "active tab is purple pill")
    check("HStack(spacing: 6)" in tabbar, "A01 tab icon+label are horizontal like PNG")
    player_idx = content.find("PlayerView()")
    live_idx = content.find("LiveView()")
    playlist_idx = content.find("PlaylistView()")
    check(player_idx != -1 and live_idx != -1 and playlist_idx != -1, "three tab views in ContentView")
    check(player_idx < live_idx < playlist_idx, "TabView order 播放器 | 现场弹幕 | 歌单")
    check("LoveSongTabBar" in content, "custom tab bar wired")

    check("Live Memory" in player or "liveMemory" in player, "A05 Live Memory header")
    check("ellipsis" in player, "A05 trailing ⋮")
    check("LiveStatusPill" in player and "现场实况" in l10n, "A04 现场实况")
    check("offset(x:" in player, "A03 stacked cover peek")
    check("MiniEQBars" in player, "cover EQ bars")
    check("DanmakuOverlay" in player, "fly danmaku kept on cover")
    check("GlassDanmakuComposer" not in player, "A16/Player: no always-on input")
    check("LikeHeartButton" in player or "toggleLike" in player, "A02 heart on player")
    check("hqBadge" in venue or "HQ" in venue, "A06 HQ badge")
    check("waveform.path.ecg" in venue, "A06 venue activity icon")
    check("accentBright" in chrome, "progress purple gradient")
    check('Circle()\n                        .fill(Color.white)' in chrome or '.fill(Color.white)' in chrome, "white progress knob")

    check("chevron.left" in live, "A09 circle back")
    check("arrow.up.left.and.arrow.down.right" in live, "A09 expand affordance")
    check("paperplane.fill" in live, "A10 purple send")
    check("face.smiling" in live, "A10 smile")
    check("liveComposerPlaceholder" in live or "发一条弹幕" in live, "A10 placeholder")
    check("showDanmakuModal" in live, "smile opens modal")
    check("FloatingHeart" not in live, "A16 floating hearts off")
    check('displayName = "我"' in identity, "A08 displayName 我")
    check("avatarPalette" in identity, "A08 color seed palette")

    check("danmakuModalHint" in modal or "发弹幕参与现场互动" in modal, "A11 hint")
    check("xmark" in modal, "A11 close")
    check("keyboard" in modal, "A11 footer keyboard")
    check("Rectangle()" in modal and "footerIcon" in modal, "A11 footer separator + icons")
    check(".sheet" not in modal, "A11 not a system sheet grid")
    check("现场封神" in phrases and "永远的经典" in phrases, "featured chips in pack")

    check("playlistReturn" in playlist or "返回当前播放" in playlist, "A13")
    check("plus" in playlist, "A12 circular +")
    check("WebUploadView" in playlist, "Wi-Fi still reachable")
    check("Concert" in l10n or "playlistConcertCountFormat" in l10n, "Concert · N")

    check("func isLiked" in favorites and "UserDefaults" in favorites, "A02 UserDefaults persistence")
    check("environment(favorites)" in app, "FavoriteStore injected")
    check('static let albumPlaceholder = "album_night_we_met"' in artwork, "album asset name")
    check('static let liveStage = "concert_live_stage"' in artwork, "live stage asset name")
    check(exists("LuluMusic/LuluMusic/Assets.xcassets/album_night_we_met.imageset/album_night_we_met.jpg"), "album in catalog")
    check(exists("LuluMusic/LuluMusic/Assets.xcassets/concert_live_stage.imageset/concert_live_stage.jpg"), "stage in catalog")
    check(exists("LuluMusic/LuluMusic/Resources/ReferenceArt/album_night_we_met.jpg"), "album in ReferenceArt")
    check(exists("LuluMusic/LuluMusic/Resources/ReferenceArt/concert_live_stage.jpg"), "stage in ReferenceArt")
    check(exists("docs/reference-screens/01-player.png"), "player PNG")
    check(exists("docs/UI-SPEC-lovesong-1to1-pixel.md"), "pixel spec present")
    check("FavoriteStoreTests.swift" in read("scripts/generate_xcodeproj.py"), "favorite tests in generator")
    check("PixelChromeTests.swift" in read("scripts/generate_xcodeproj.py"), "pixel tests in generator")
    check("testA14TimestampModelHasTrackIdAndMillisecond" in read("LuluMusic/LoveSongTests/PixelChromeTests.swift"), "A14 XCTest")
    check("testA15DanmakuRecordHasNoSocialIdentityFields" in read("LuluMusic/LoveSongTests/PixelChromeTests.swift"), "A15 XCTest")
    check("testA11FeaturedChipsAreImmediateSendPhrasesNotDraftOnly" in read("LuluMusic/LoveSongTests/PixelChromeTests.swift"), "A11 XCTest")


def test_amend_must_ids() -> None:
    """Frozen PRD Amend A01–A15. Overrides older Drop-Like."""
    content = read("LuluMusic/LuluMusic/ContentView.swift")
    chrome = read("LuluMusic/LuluMusic/Views/PlayerChrome.swift")
    l10n = read("LuluMusic/LuluMusic/Theme/L10n.swift")
    player = read("LuluMusic/LuluMusic/Views/PlayerView.swift")
    live = read("LuluMusic/LuluMusic/Views/LiveView.swift")
    modal = read("LuluMusic/LuluMusic/Views/DanmakuModal.swift")
    playlist = read("LuluMusic/LuluMusic/Views/PlaylistView.swift")
    venue = read("LuluMusic/LuluMusic/Views/StageComponents.swift")
    comment = read("LuluMusic/LuluMusic/Models/DanmakuComment.swift")
    record = read("LuluMusic/LuluMusic/Core/DanmakuCore.swift")
    favorites = read("LuluMusic/LuluMusic/Core/FavoriteStore.swift")
    identity = read("LuluMusic/LuluMusic/Core/LocalDanmakuIdentity.swift")
    phrases = read("LuluMusic/LuluMusic/Core/DanmakuPhrasePack.swift")
    tests = read("LuluMusic/LoveSongTests/PixelChromeTests.swift") + read("LuluMusic/LoveSongTests/FavoriteStoreTests.swift")

    # A01
    check('tabPlayer = "播放器"' in l10n and 'tabLive = "现场弹幕"' in l10n and 'tabPlaylist = "歌单"' in l10n, "A01 copy")
    check(content.find("PlayerView()") < content.find("LiveView()") < content.find("PlaylistView()"), "A01 tab order")
    check("Capsule()" in read("LuluMusic/LuluMusic/Views/LoveSongTabBar.swift"), "A01 purple pill")
    check('["播放器", "现场弹幕", "歌单"]' in tests, "A01 XCTest titles")

    # A02
    check("LikeHeartButton" in chrome and "heart.fill" in chrome, "A02 purple heart control")
    check("UserDefaults" in favorites and "func isLiked" in favorites, "A02 local persist")
    check("testTogglePersistsLikedStateForTrack" in tests, "A02 persist XCTest")

    # A03–A07
    check("stackedCover" in player and "offset(x:" in player, "A03 stacked cover")
    check("LiveStatusPill" in player and "liveStatusPill" in l10n, "A04 现场实况")
    check("liveMemory" in player or "Live Memory" in player, "A05 Live Memory")
    check("hqBadge" in venue and "onOpenLive" in venue, "A06 venue + HQ")
    check("tab = .live" in player, "A06 tap venue/cover → 现场弹幕")
    check("SpotlightPlayButton" in chrome and "accentGlow" in chrome, "A07 large purple play glow")

    # A08–A10
    check('displayName = "我"' in identity, "A08 display 我")
    check("DanmakuAvatarBubble" in live and "LiveDanmakuWindow" in live, "A08 bubble chrome + timestamp window")
    check("userId" not in comment and "nickname" not in comment, "A08/A15 no fake user fields on DanmakuComment")
    check("Luna" not in live and "阿哲" not in live, "A08 no seeded multi-user nicks in Live")
    check("chevron.left" in live, "A09 back")
    check("LiveComposerPill" in live and "paperplane.fill" in live, "A10 input send")
    check("showDanmakuModal" in live, "A10 smile → modal")

    # A11
    check("现场封神" in phrases and "万人大合唱" in phrases, "A11 chips")
    check("onSend(phrase)" in modal, "A11 chip tap sends immediately")
    check("xmark" in modal and "danmakuModalHint" in modal, "A11 close + hint")

    # A12–A13
    check("playlistTitle" in playlist and "plus" in playlist, "A12 card +")
    check("playlistReturn" in playlist and "tab = .player" in playlist, "A13 返回当前播放")
    check("WebUploadView" in playlist, "A14 Wi-Fi from playlist")

    # A14
    check("trackId" in record and "timestampMS" in record, "A14 timestamp model")
    check("spawnLeadMS: Int = 500" in record, "A14 500ms lead kept")

    # A15
    check("userId" not in comment, "A15 no userId")
    check("FloatingHeart" not in live, "A15/A16 no social hearts")


def test_duration_and_scrub_algorithms() -> None:
    import subprocess
    import sys

    result = subprocess.run(
        [sys.executable, str(ROOT / "scripts" / "test_playback_timing.py")],
        capture_output=True,
        text=True,
    )
    check(result.returncode == 0, f"playback timing twin: {result.stdout.strip()} {result.stderr.strip()}")
    time_format = read("LuluMusic/LuluMusic/Theme/AppTheme.swift")
    check("TrackDuration.playbackSeconds" in time_format, "TimeFormat normalizes units")


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
        test_duration_and_scrub_algorithms,
        test_wifi_ui_and_plist,
        test_no_now_playing_matched_geometry,
        test_live_visible_window,
        test_theme_black_purple_white,
        test_three_tab_ia,
        test_pixel_1to1,
        test_amend_must_ids,
        test_project_wires_tests,
    ):
        fn()
    if failures:
        print("FAILED")
        for f in failures:
            print(" -", f)
        raise SystemExit(1)
    print("OK: LoveSong UI Refresh contracts + P0 logic + XCTest wiring checks passed")
    print("Mac: xcodebuild test -project LuluMusic/LuluMusic.xcodeproj -scheme LoveSong -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:LoveSongTests")


if __name__ == "__main__":
    main()
