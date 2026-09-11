import SwiftUI

struct LoveSongTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                let selected = selection == tab
                Button {
                    selection = tab
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tab.systemImage)
                            .font(.system(size: 15, weight: .semibold))
                        Text(tab.title)
                            .font(LoveSongTheme.Font.tabLabel)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                    }
                    .foregroundStyle(selected ? Color.white : LoveSongTheme.textSecondary)
                    .padding(.horizontal, selected ? 14 : 8)
                    .padding(.vertical, 8)
                    .background {
                        if selected {
                            Capsule()
                                .fill(LoveSongTheme.accent.opacity(0.92))
                                .shadow(color: LoveSongTheme.accentGlow.opacity(0.42), radius: 12, y: 0)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(selected ? [.isSelected] : [])
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background {
            Rectangle()
                .fill(LoveSongTheme.stageElevated.opacity(0.94))
                .background(.ultraThinMaterial)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(LoveSongTheme.hairline)
                        .frame(height: 0.5)
                }
                .ignoresSafeArea(edges: .bottom)
        }
    }
}
