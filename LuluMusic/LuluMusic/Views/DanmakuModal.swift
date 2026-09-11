import SwiftUI
import UIKit

struct DanmakuModal: View {
    var enabled: Bool
    var onPick: (String) -> Void

    private let phrases = [
        "起鸡皮疙瘩了",
        "副歌太绝了",
        "泪目",
        "这段神仙",
        "安可！！",
        "好想再去一次",
        "灯光美",
        "声音封神"
    ]
    private let emojis = ["🔥", "💜", "😭", "🎤", "✨", "Encore"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        ForEach(phrases, id: \.self) { phrase in
                            Button {
                                guard enabled else { return }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                onPick(phrase)
                            } label: {
                                Text(phrase)
                                    .font(LoveSongTheme.Font.body)
                                    .foregroundStyle(LoveSongTheme.textPrimary)
                                    .frame(maxWidth: .infinity, minHeight: 44)
                                    .padding(.horizontal, 8)
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(LoveSongTheme.hairline, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                            .disabled(!enabled)
                        }
                    }

                    HStack(spacing: 12) {
                        ForEach(emojis, id: \.self) { emoji in
                            Button {
                                guard enabled else { return }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                onPick(emoji)
                            } label: {
                                Text(emoji)
                                    .font(.title3)
                                    .frame(width: 44, height: 44)
                                    .background(.ultraThinMaterial, in: Circle())
                            }
                            .buttonStyle(.plain)
                            .disabled(!enabled)
                        }
                    }
                }
                .padding(16)
            }
            .background(LoveSongTheme.stageElevated.ignoresSafeArea())
            .navigationTitle(L10n.danmakuModalTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(LoveSongTheme.stageElevated, for: .navigationBar)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
