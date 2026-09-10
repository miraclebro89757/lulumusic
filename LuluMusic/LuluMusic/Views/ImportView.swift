import SwiftUI

struct ImportView: View {
    @Environment(LibraryService.self) private var library
    @State private var showFiles = false
    @State private var showAppleMusic = false
    @State private var appleDenied = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    header

                    ImportCard(
                        icon: "folder.fill.badge.plus",
                        title: L10n.importFilesTitle,
                        subtitle: L10n.importFilesSubtitle,
                        button: L10n.importFilesButton
                    ) {
                        showFiles = true
                    }

                    ImportCard(
                        icon: "music.note.house.fill",
                        title: L10n.importAppleTitle,
                        subtitle: L10n.importAppleSubtitle,
                        button: L10n.importAppleButton
                    ) {
                        Task { await openAppleMusic() }
                    }

                    NavigationLink {
                        WebUploadView()
                    } label: {
                        ImportCardLabel(
                            icon: "wifi",
                            title: L10n.importWebTitle,
                            subtitle: L10n.importWebSubtitle,
                            button: L10n.importWebButton
                        )
                    }
                    .buttonStyle(.plain)

                    if library.isImporting {
                        HStack(spacing: 10) {
                            ProgressView()
                            Text(L10n.importing)
                        }
                        .padding(.top, 8)
                    }

                    if let message = library.bannerMessage {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .padding(16)
                .padding(.bottom, 80)
            }
            .navigationTitle(L10n.tabImport)
            .sheet(isPresented: $showFiles) {
                AudioDocumentPicker { urls in
                    showFiles = false
                    Task { await library.importFiles(from: urls, source: .files) }
                }
                .ignoresSafeArea()
            }
            .sheet(isPresented: $showAppleMusic) {
                AppleMusicPicker { items in
                    showAppleMusic = false
                    Task { await library.importMediaItems(items) }
                } onCancel: {
                    showAppleMusic = false
                }
                .ignoresSafeArea()
            }
            .alert(L10n.importFailed, isPresented: $appleDenied) {
                Button(L10n.done, role: .cancel) {}
            } message: {
                Text(L10n.appleMusicDenied)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.importTitle)
                .font(.title2.weight(.bold))
            Text("文件会复制到 App 沙盒，可离线播放。网页上传仅在同一 Wi‑Fi 下有效。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 4)
    }

    private func openAppleMusic() async {
        let status = await MusicLibraryAuth.request()
        switch status {
        case .authorized:
            showAppleMusic = true
        default:
            appleDenied = true
        }
    }
}

struct ImportCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let button: String
    var action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 36, height: 36)
                Text(title)
                    .font(.headline)
            }
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button(action: action) {
                Text(button)
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

struct ImportCardLabel: View {
    let icon: String
    let title: String
    let subtitle: String
    let button: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 36, height: 36)
                Text(title)
                    .font(.headline)
            }
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                Text(button)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
