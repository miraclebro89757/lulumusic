import SwiftUI
import UIKit

struct LiveView: View {
    @Environment(PlayerEngine.self) private var player
    @Environment(DanmakuService.self) private var danmakuService
    @Environment(AppNavigation.self) private var navigation
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var catalog: [DanmakuRecord] = []
    @State private var draft = ""
    @State private var showPhrases = false
    @State private var didShowEmptyHint = false
    @FocusState private var inputFocused: Bool

    private var visibleBubbles: [DanmakuRecord] {
        guard player.danmakuEnabled else { return [] }
        return LiveDanmakuWindow.visible(records: catalog, nowMS: player.currentTimeMS)
    }

    var body: some View {
        ZStack {
            liveBackground

            if player.current == nil {
                EmptyStateView(
                    systemImage: "opticaldisc",
                    title: L10n.liveEmptyTrack,
                    primaryTitle: L10n.tabPlaylist,
                    primaryAction: { navigation.tab = .playlist }
                )
            } else {
                VStack(spacing: 0) {
                    header
                    Spacer(minLength: 0)
                    bubbleStack
                    GlassDanmakuComposer(
                        text: $draft,
                        enabled: true,
                        focused: $inputFocused,
                        onSend: sendDanmaku,
                        onSmile: { showPhrases = true }
                    )
                    .padding(.horizontal, LoveSongTheme.Space.screen)
                    .padding(.bottom, 8)
                }
            }
        }
        .onAppear(perform: reloadCatalog)
        .onChange(of: navigation.tab) { _, tab in
            if tab == .live { reloadCatalog() }
        }
        .onChange(of: player.current?.id) { _, _ in
            reloadCatalog()
        }
        .onChange(of: player.currentTimeMS) { _, _ in
            // Visible set is derived; this refresh keeps seek-rebuild in view.
            if catalog.isEmpty { reloadCatalog() }
        }
        .sheet(isPresented: $showPhrases) {
            DanmakuModal(
                enabled: player.current != nil,
                onPick: { phrase in
                    showPhrases = false
                    sendPhrase(phrase)
                }
            )
        }
    }

    private var liveBackground: some View {
        ConcertStageBackground(
            url: player.current?.artworkURL,
            seed: (player.current?.title ?? "") + (player.current?.artist ?? "empty")
        )
    }

    private var header: some View {
        HStack(spacing: 8) {
            Button {
                navigation.tab = .player
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text(L10n.liveBack)
                }
                .font(.body.weight(.semibold))
                .foregroundStyle(LoveSongTheme.textPrimary)
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().stroke(LoveSongTheme.hairline, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.liveBack)

            Spacer()
            if let title = player.current?.title {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(LoveSongTheme.textTertiary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, LoveSongTheme.Space.screen)
        .padding(.top, 8)
    }

    private var bubbleStack: some View {
        VStack(alignment: .leading, spacing: 8) {
            if visibleBubbles.isEmpty && player.current != nil && !didShowEmptyHint {
                Text(L10n.liveEmptyDanmaku)
                    .font(.caption)
                    .foregroundStyle(LoveSongTheme.textTertiary)
                    .onAppear { didShowEmptyHint = true }
            }
            ForEach(visibleBubbles) { record in
                DanmakuBubble(text: record.text)
                    .transition(reduceMotion ? .opacity : .asymmetric(
                        insertion: .opacity.combined(with: .offset(y: 12)),
                        removal: .opacity
                    ))
            }
        }
        .frame(maxWidth: 280, alignment: .leading)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .padding(.leading, 16)
        .padding(.bottom, 12)
        .animation(reduceMotion ? .none : .easeOut(duration: 0.22), value: visibleBubbles.map(\.id))
    }

    private func sendPhrase(_ text: String) {
        draft = text
        sendDanmaku()
    }

    private func sendDanmaku() {
        guard let id = player.current?.id else { return }
        guard let normalized = DanmakuText.normalized(draft) else { return }
        let record = DanmakuRecord(
            trackId: id,
            timestampMS: player.livePlayerMilliseconds(),
            text: normalized
        )
        draft = ""
        catalog.append(record)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        Task { danmakuService.persist(record) }
    }

    private func reloadCatalog() {
        guard let id = player.current?.id else {
            catalog = []
            return
        }
        catalog = danmakuService.records(for: id)
    }
}

struct DanmakuBubble: View {
    var text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(LoveSongTheme.accent)
                .frame(width: 6, height: 6)
                .padding(.top, 8)
            VStack(alignment: .leading, spacing: 2) {
                Text("我")
                    .font(.caption2)
                    .foregroundStyle(LoveSongTheme.textTertiary)
                Text(text)
                    .font(LoveSongTheme.Font.body)
                    .foregroundStyle(LoveSongTheme.textPrimary)
                    .lineLimit(4)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(LoveSongTheme.bubbleFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(LoveSongTheme.hairline, lineWidth: 1)
        )
        .accessibilityLabel("弹幕：\(text)")
    }
}
