import SwiftUI
import UIKit

struct WebUploadView: View {
    @Environment(LibraryService.self) private var library
    @Environment(\.scenePhase) private var scenePhase
    @State private var server = WebUploadServer()
    @State private var copiedURL = false
    @State private var copiedPairing = false

    var body: some View {
        ZStack {
            LoveSongTheme.stageFill
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(L10n.webUploadHint)
                        .font(.body)
                        .foregroundStyle(LoveSongTheme.textSecondary)
                    Text(LANBindPolicy.stayOpenBanner)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(LoveSongTheme.textSecondary)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(LoveSongTheme.stageElevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                    statusCard
                    if server.isRunning {
                        addressCard
                    } else {
                        HStack(spacing: 8) {
                            ProgressView()
                                .tint(LoveSongTheme.accent)
                            Text(L10n.openingServer)
                                .font(.subheadline)
                                .foregroundStyle(LoveSongTheme.textSecondary)
                        }
                        .padding(.vertical, 8)
                    }
                    if server.lanIPs.isEmpty {
                        permissionCard
                    }
                    uploadsCard
                }
                .padding(20)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle(L10n.webUploadTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(LoveSongTheme.stageBackground, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            LocalNetworkAccess.request()
            startServer()
        }
        .onDisappear {
            LocalNetworkAccess.end()
            server.stop()
        }
        .onChange(of: scenePhase) { _, phase in
            let runtime: AppRuntimePhase
            switch phase {
            case .active: runtime = .foregroundActive
            case .inactive: runtime = .inactive
            case .background: runtime = .background
            @unknown default: runtime = .inactive
            }
            if WebImportLifecycle.shouldServe(pageVisible: true, phase: runtime) {
                startServer()
            } else {
                server.stop()
            }
        }
    }

    private var statusCard: some View {
        StageSurface {
            HStack(spacing: 10) {
                Circle()
                    .fill(server.isRunning ? LoveSongTheme.success : LoveSongTheme.textTertiary)
                    .frame(width: 8, height: 8)
                VStack(alignment: .leading, spacing: 3) {
                    Text(server.statusText)
                        .font(.headline)
                        .foregroundStyle(LoveSongTheme.textPrimary)
                    if let error = server.lastError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(LoveSongTheme.error)
                    } else if server.lanIPs.isEmpty && server.isRunning {
                        Text(L10n.noWiFi)
                            .font(.caption)
                            .foregroundStyle(LoveSongTheme.textSecondary)
                    }
                }
                Spacer()
            }
        }
    }

    private var addressCard: some View {
        StageSurface {
            VStack(alignment: .leading, spacing: 10) {
                Text(L10n.lanAddress)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(LoveSongTheme.textSecondary)
                if server.publicURLString.isEmpty {
                    Text(L10n.noWiFi)
                        .foregroundStyle(LoveSongTheme.textSecondary)
                } else {
                    Text(server.publicURLString)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(LoveSongTheme.textPrimary)
                        .textSelection(.enabled)
                    Button {
                        UIPasteboard.general.string = server.publicURLString
                        copiedURL = true
                    } label: {
                        Label(copiedURL ? L10n.copied : L10n.copyURL, systemImage: copiedURL ? "checkmark" : "doc.on.doc")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(LoveSongTheme.accent)
                    }
                    Text(L10n.pairingCode)
                        .font(.caption)
                        .foregroundStyle(LoveSongTheme.textSecondary)
                        .padding(.top, 6)
                    Text(server.pairingDigits)
                        .font(LoveSongTheme.Font.pairing)
                        .foregroundStyle(LoveSongTheme.textPrimary)
                        .tracking(10)
                        .textSelection(.enabled)
                    Text(L10n.pairingHint)
                        .font(.caption)
                        .foregroundStyle(LoveSongTheme.textTertiary)
                    Button {
                        UIPasteboard.general.string = server.pairingDigits
                        copiedPairing = true
                    } label: {
                        Label(copiedPairing ? L10n.copied : L10n.copyPairing, systemImage: copiedPairing ? "checkmark" : "doc.on.doc")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(LoveSongTheme.accent)
                    }
                    ForEach(server.lanIPs.dropFirst(), id: \.self) { ip in
                        Text("http://\(ip):\(server.port)")
                            .font(.caption.monospaced())
                            .foregroundStyle(LoveSongTheme.textTertiary)
                            .textSelection(.enabled)
                    }
                }
            }
        }
    }

    private var permissionCard: some View {
        StageSurface {
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.wifiDenied)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(LoveSongTheme.textPrimary)
                Text(L10n.noWiFi)
                    .font(.footnote)
                    .foregroundStyle(LoveSongTheme.textSecondary)
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text(L10n.wifiOpenSettings)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(LoveSongTheme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var uploadsCard: some View {
        StageSurface {
            VStack(alignment: .leading, spacing: 12) {
                Text(server.tasks.isEmpty ? L10n.waitingUpload : L10n.receiving)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(LoveSongTheme.textSecondary)
                if server.tasks.isEmpty {
                    Text("电脑浏览器打开链接后，将音频拖进页面即可。进度会显示在这里。")
                        .font(.footnote)
                        .foregroundStyle(LoveSongTheme.textTertiary)
                }
                ForEach(server.tasks) { task in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(task.fileName)
                                .foregroundStyle(LoveSongTheme.textPrimary)
                                .lineLimit(1)
                            Spacer()
                            Text(task.message ?? "")
                                .font(.caption)
                                .foregroundStyle(task.state == .failed ? LoveSongTheme.error : LoveSongTheme.textTertiary)
                        }
                        ProgressView(value: task.fraction)
                            .tint(LoveSongTheme.accent)
                        if task.totalBytes > 0 {
                            Text("\(byteText(task.bytesReceived)) / \(byteText(task.totalBytes))")
                                .font(.caption2)
                                .foregroundStyle(LoveSongTheme.textTertiary)
                        }
                    }
                }
            }
        }
    }

    private func startServer() {
        server.onFileReady = { url, name in
            _ = try await library.importFile(from: url, source: .web, originalName: name)
        }
        server.start()
        copiedURL = false
        copiedPairing = false
    }

    private func byteText(_ value: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: value)
    }
}
