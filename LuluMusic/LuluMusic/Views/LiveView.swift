import SwiftUI
import UIKit

struct LiveView: View {
    @Environment(PlayerEngine.self) private var player
    @Environment(DanmakuService.self) private var danmakuService
    @Environment(AppNavigation.self) private var navigation
    @Environment(FavoriteStore.self) private var favorites
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var catalog: [DanmakuRecord] = []
    @State private var draft = ""
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
                    LiveComposerPill(
                        text: $draft,
                        enabled: true,
                        focused: $inputFocused,
                        onSend: sendDanmaku,
                        onSmile: { navigation.showDanmakuModal = true }
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
                }
            }

            if navigation.showDanmakuModal {
                DanmakuModal(
                    enabled: player.current != nil,
                    liked: currentLiked,
                    draft: $draft,
                    onClose: { navigation.showDanmakuModal = false },
                    onToggleLike: toggleLike,
                    onSend: { text in
                        navigation.showDanmakuModal = false
                        sendPhrase(text)
                    }
                )
                .transition(.opacity)
                .zIndex(2)
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .animation(.easeOut(duration: 0.18), value: navigation.showDanmakuModal)
        .onAppear(perform: reloadCatalog)
        .onChange(of: navigation.tab) { _, tab in
            if tab == .live { reloadCatalog() }
        }
        .onChange(of: player.current?.id) { _, _ in
            reloadCatalog()
        }
        .onChange(of: player.currentTimeMS) { _, _ in
            if catalog.isEmpty { reloadCatalog() }
        }
    }

    private var currentLiked: Bool {
        guard let id = player.current?.id else { return false }
        return favorites.isLiked(id)
    }

    private var liveBackground: some View {
        ConcertStageBackground(
            url: player.current?.artworkURL,
            seed: (player.current?.title ?? "") + (player.current?.artist ?? "empty"),
            fallbackAsset: ReferenceArt.liveStage,
            dim: 0.36
        )
    }

    private var header: some View {
        HStack {
            Button {
                navigation.tab = .player
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(LoveSongTheme.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().stroke(LoveSongTheme.hairline, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.liveBack)

            Spacer()

            HStack(spacing: 8) {
                Circle()
                    .fill(LoveSongTheme.accent)
                    .frame(width: 7, height: 7)
                Text("\(L10n.liveLabel) · \(ConcertDateFormat.short(player.current?.addedAt ?? Date()))")
                    .font(LoveSongTheme.Font.livePill)
                    .foregroundStyle(LoveSongTheme.textPrimary)
                Rectangle()
                    .fill(Color.white.opacity(0.22))
                    .frame(width: 1, height: 12)
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(LoveSongTheme.textSecondary)
            }
            .padding(.horizontal, 12)
            .frame(height: 36)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(LoveSongTheme.hairline, lineWidth: 1))
            .accessibilityLabel("\(L10n.liveLabel) \(ConcertDateFormat.short(player.current?.addedAt ?? Date()))")
        }
        .padding(.horizontal, 16)
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
                DanmakuAvatarBubble(record: record)
                    .transition(reduceMotion ? .opacity : .asymmetric(
                        insertion: .opacity.combined(with: .offset(y: 12)),
                        removal: .opacity
                    ))
            }
        }
        .frame(maxWidth: 300, alignment: .leading)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .padding(.leading, 14)
        .padding(.bottom, 14)
        .animation(reduceMotion ? .none : .easeOut(duration: 0.22), value: visibleBubbles.map(\.id))
    }

    private func toggleLike() {
        guard let id = player.current?.id else { return }
        favorites.toggle(id)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
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

struct DanmakuAvatarBubble: View {
    var record: DanmakuRecord

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color(hex: LocalDanmakuIdentity.avatarHex(for: record.id)))
                Text(LocalDanmakuIdentity.avatarLetter(for: record))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.white)
            }
            .frame(width: 30, height: 30)

            HStack(spacing: 6) {
                Text(LocalDanmakuIdentity.displayName(for: record))
                    .font(LoveSongTheme.Font.bubbleName)
                    .foregroundStyle(LoveSongTheme.textPrimary)
                Text(record.text)
                    .font(LoveSongTheme.Font.body)
                    .foregroundStyle(LoveSongTheme.textPrimary)
                    .lineLimit(4)
            }
        }
        .padding(.leading, 8)
        .padding(.trailing, 14)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.58), in: Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 1))
        .accessibilityLabel("弹幕：\(record.text)")
    }
}

struct LiveComposerPill: View {
    @Binding var text: String
    var enabled: Bool
    var focused: FocusState<Bool>.Binding
    var onSend: () -> Void
    var onSmile: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onSmile) {
                Image(systemName: "face.smiling")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(LoveSongTheme.textSecondary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .disabled(!enabled)
            .accessibilityLabel(L10n.danmakuSmile)

            TextField(L10n.liveComposerPlaceholder, text: $text)
                .textFieldStyle(.plain)
                .font(.subheadline)
                .foregroundStyle(LoveSongTheme.textPrimary)
                .focused(focused)
                .submitLabel(.send)
                .disabled(!enabled)
                .onSubmit(onSend)
                .accessibilityLabel(L10n.liveComposerPlaceholder)

            Button(action: onSend) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .frame(width: 40, height: 40)
                    .background(LoveSongTheme.accent, in: Circle())
                    .shadow(color: LoveSongTheme.accentGlow.opacity(0.45), radius: 10, y: 0)
            }
            .buttonStyle(.plain)
            .disabled(!enabled || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(enabled && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 1 : 0.45)
            .accessibilityLabel(L10n.danmakuSend)
        }
        .padding(.leading, 6)
        .padding(.trailing, 6)
        .frame(height: 52)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(LoveSongTheme.hairline, lineWidth: 1))
    }
}
