import SwiftUI
import UIKit

struct DanmakuModal: View {
    var enabled: Bool
    var liked: Bool
    @Binding var draft: String
    var onClose: () -> Void
    var onToggleLike: () -> Void
    var onSend: (String) -> Void
    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.42)
                .background(.ultraThinMaterial.opacity(0.28))
                .onTapGesture(perform: onClose)

            VStack(spacing: 0) {
                HStack {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(LoveSongTheme.textPrimary)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("关闭")
                    Spacer()
                    Text(L10n.danmakuModalHint)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(LoveSongTheme.textTertiary)
                }

                HStack(spacing: 10) {
                    Button(action: onToggleLike) {
                        Image(systemName: liked ? "heart.fill" : "heart")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(LoveSongTheme.accent)
                            .frame(width: 44, height: 44)
                            .overlay(Circle().stroke(LoveSongTheme.accent.opacity(0.78), lineWidth: 1.4))
                            .shadow(color: LoveSongTheme.accentGlow.opacity(liked ? 0.5 : 0.28), radius: 8, y: 0)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(liked ? L10n.unlike : L10n.like)

                    TextField(L10n.liveComposerPlaceholder, text: $draft)
                        .textFieldStyle(.plain)
                        .font(.subheadline)
                        .foregroundStyle(LoveSongTheme.textPrimary)
                        .focused($focused)
                        .submitLabel(.send)
                        .padding(.horizontal, 16)
                        .frame(height: 44)
                        .background(Color.black.opacity(0.28), in: Capsule())
                        .overlay(
                            Capsule()
                                .stroke(LoveSongTheme.accent.opacity(0.85), lineWidth: 1.2)
                                .shadow(color: LoveSongTheme.accentGlow.opacity(0.55), radius: 8, y: 0)
                        )
                        .onSubmit(sendDraft)

                    Button(action: sendDraft) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.white)
                            .frame(width: 44, height: 44)
                            .background(LoveSongTheme.accent, in: Circle())
                            .shadow(color: LoveSongTheme.accentGlow.opacity(0.55), radius: 12, y: 0)
                    }
                    .buttonStyle(.plain)
                    .disabled(!enabled)
                    .accessibilityLabel(L10n.danmakuSend)
                }
                .padding(.top, 8)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(DanmakuPhrasePack.featured, id: \.self) { phrase in
                            Button {
                                guard enabled else { return }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                onSend(phrase)
                            } label: {
                                Text(phrase)
                                    .font(LoveSongTheme.Font.chip)
                                    .foregroundStyle(LoveSongTheme.textPrimary)
                                    .padding(.horizontal, 12)
                                    .frame(height: 34)
                                    .background(Color.white.opacity(0.06), in: Capsule())
                                    .overlay(Capsule().stroke(Color.white.opacity(0.14), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                            .disabled(!enabled)
                        }
                    }
                }
                .padding(.top, 16)

                Rectangle()
                    .fill(Color.white.opacity(0.10))
                    .frame(height: 1)
                    .padding(.top, 16)

                HStack {
                    Spacer()
                    footerIcon("face.smiling") { focused = true }
                    footerIcon("bubble.left") { focused = true }
                    footerIcon("keyboard") { focused = true }
                }
                .padding(.top, 10)
            }
            .padding(18)
            .background {
                RoundedRectangle(cornerRadius: LoveSongTheme.Space.modalRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: LoveSongTheme.Space.modalRadius, style: .continuous)
                            .fill(Color(hex: 0x140C22).opacity(0.82))
                    }
            }
            .overlay(
                RoundedRectangle(cornerRadius: LoveSongTheme.Space.modalRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .padding(.horizontal, 22)
        }
        .onAppear { focused = true }
    }

    private func sendDraft() {
        guard enabled, DanmakuText.normalized(draft) != nil else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        onSend(draft)
    }

    private func footerIcon(_ name: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: name)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(LoveSongTheme.textTertiary)
                .frame(width: 36, height: 36)
        }
        .buttonStyle(.plain)
    }
}
