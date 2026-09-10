import SwiftUI

struct VenueChip: View {
    var text: String
    var compact: Bool = false

    var body: some View {
        Text(text)
            .font(LoveSongTheme.Font.chip)
            .foregroundStyle(LoveSongTheme.textPrimary)
            .lineLimit(1)
            .padding(.horizontal, compact ? 8 : 11)
            .padding(.vertical, compact ? 3 : 5)
            .overlay(
                Capsule()
                    .stroke(LoveSongTheme.spotlight.opacity(0.9), lineWidth: 1)
            )
    }
}

/// Opaque elevated card for browsing/import — not glass.
struct StageSurface<Content: View>: View {
    var padded: Bool = true
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padded ? 16 : 0)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LoveSongTheme.stageElevated, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(LoveSongTheme.hairline, lineWidth: 1)
            )
    }
}

struct StageSearchField: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(LoveSongTheme.textTertiary)
            TextField(L10n.searchPrompt, text: $text)
                .textFieldStyle(.plain)
                .foregroundStyle(LoveSongTheme.textPrimary)
                .tint(LoveSongTheme.spotlight)
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(LoveSongTheme.textTertiary)
                }
            }
        }
        .font(.subheadline)
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(LoveSongTheme.stageElevated, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(LoveSongTheme.hairline, lineWidth: 1)
        )
    }
}

struct QuietImportBar: View {
    var onFiles: () -> Void
    var onWifi: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onWifi) {
                HStack(spacing: 8) {
                    Image(systemName: "wifi")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(LoveSongTheme.spotlight)
                    Text(L10n.wifiImportShort)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(LoveSongTheme.textSecondary)
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(LoveSongTheme.textTertiary)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.importWebButton)

            Spacer(minLength: 8)

            Button(action: onFiles) {
                HStack(spacing: 6) {
                    Image(systemName: "folder")
                    Text(L10n.filesImportShort)
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(LoveSongTheme.textSecondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.importFilesButton)
        }
        .padding(.vertical, 4)
    }
}
