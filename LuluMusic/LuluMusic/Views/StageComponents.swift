import SwiftUI

struct VenueChip: View {
    var text: String
    var compact: Bool = false

    var body: some View {
        Text(text)
            .font(LoveSongTheme.Font.chip)
            .foregroundStyle(LoveSongTheme.textSecondary)
            .lineLimit(1)
            .padding(.horizontal, compact ? 8 : 11)
            .padding(.vertical, compact ? 3 : 5)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(
                Capsule()
                    .stroke(LoveSongTheme.hairline, lineWidth: 1)
            )
    }
}

struct VenueGlassStrip: View {
    var text: String
    var dateText: String
    var onOpenLive: () -> Void
    var onEdit: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(LoveSongTheme.accent.opacity(0.22))
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(LoveSongTheme.accent)
            }
            .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(L10n.liveLabel) · \(dateText)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(LoveSongTheme.textPrimary)
                Text(text.isEmpty ? L10n.venueAdd : text)
                    .font(.subheadline)
                    .foregroundStyle(text.isEmpty ? LoveSongTheme.textTertiary : LoveSongTheme.textPrimary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(L10n.hqBadge)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(LoveSongTheme.textPrimary.opacity(0.88))
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .overlay(
                    Capsule().stroke(Color.white.opacity(0.42), lineWidth: 1)
                )
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 48)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(LoveSongTheme.hairline, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onOpenLive)
        .onLongPressGesture {
            onEdit?()
        }
        .accessibilityLabel(text.isEmpty ? "\(L10n.venueAdd)，仍可进入现场" : "现场标签，\(text)，进入现场")
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
            .background(LoveSongTheme.stageElevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(LoveSongTheme.hairline, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.28), radius: 16, y: 8)
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
                .tint(LoveSongTheme.accent)
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(LoveSongTheme.textTertiary)
                        .frame(width: 44, height: 36)
                }
            }
        }
        .font(.subheadline)
        .padding(.horizontal, 14)
        .frame(height: 36)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(LoveSongTheme.hairline, lineWidth: 1)
        )
    }
}

struct EmptyStateView: View {
    var systemImage: String
    var title: String
    var subtitle: String? = nil
    var primaryTitle: String
    var primaryAction: () -> Void
    var secondaryTitle: String? = nil
    var secondaryAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 18) {
            Spacer(minLength: LoveSongTheme.Space.heroEmpty)
            Image(systemName: systemImage)
                .font(.system(size: 48, weight: .regular))
                .foregroundStyle(LoveSongTheme.textSecondary)
            Text(title)
                .font(LoveSongTheme.Font.emptyTitle)
                .foregroundStyle(LoveSongTheme.textPrimary)
                .multilineTextAlignment(.center)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(LoveSongTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }
            Button(action: primaryAction) {
                Text(primaryTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.white)
                    .frame(minHeight: 48)
                    .padding(.horizontal, 22)
                    .background(LoveSongTheme.accent, in: Capsule())
            }
            if let secondaryTitle, let secondaryAction {
                Button(action: secondaryAction) {
                    Text(secondaryTitle)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(LoveSongTheme.accent)
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: LoveSongTheme.Space.heroEmpty)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
