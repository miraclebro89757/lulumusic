import SwiftUI
import UIKit

struct WebUploadView: View {
    @Environment(LibraryService.self) private var library
    @Environment(\.scenePhase) private var scenePhase
    @State private var server = WebUploadServer()
    @State private var copied = false

    var body: some View {
        ZStack {
            LoveSongTheme.stageFill
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(L10n.webUploadHint)
                        .font(.subheadline)
                        .foregroundStyle(LoveSongTheme.textSecondary)
                    Text(L10n.keepForeground)
                        .font(.footnote)
                        .foregroundStyle(LoveSongTheme.textTertiary)

                    statusCard
                    if server.isRunning {
                        addressCard
                        qrCard
                    }
                    uploadsCard
                }
                .padding(LoveSongTheme.Space.screen)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle(L10n.webUploadTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(LoveSongTheme.stageBackground, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(server.isRunning ? L10n.stopServer : L10n.startServer) {
                    if server.isRunning {
                        server.stop()
                    } else {
                        startServer()
                    }
                }
                .foregroundStyle(LoveSongTheme.spotlight)
            }
        }
        .onAppear { startServer() }
        .onDisappear { server.stop() }
        .onChange(of: scenePhase) { _, phase in
            let runtime: AppRuntimePhase
            switch phase {
            case .active: runtime = .foregroundActive
            case .inactive: runtime = .inactive
            case .background: runtime = .background
            @unknown default: runtime = .inactive
            }
            if !WebImportLifecycle.shouldServe(pageVisible: true, phase: runtime) {
                server.stop()
            }
        }
    }

    private var statusCard: some View {
        StageSurface {
            HStack(spacing: 10) {
                Circle()
                    .fill(server.isRunning ? LoveSongTheme.spotlight : LoveSongTheme.textTertiary)
                    .frame(width: 8, height: 8)
                VStack(alignment: .leading, spacing: 3) {
                    Text(server.statusText)
                        .font(.headline)
                        .foregroundStyle(LoveSongTheme.textPrimary)
                    if let error = server.lastError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    } else if server.lanIPs.isEmpty && server.isRunning {
                        Text(L10n.noWiFi)
                            .font(.caption)
                            .foregroundStyle(LoveSongTheme.spotlight)
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
                    Text(L10n.pairingCode)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(LoveSongTheme.textSecondary)
                        .padding(.top, 6)
                    Text(server.pairingDigits)
                        .font(LoveSongTheme.Font.pairing)
                        .foregroundStyle(LoveSongTheme.spotlight)
                        .tracking(10)
                    Text(L10n.pairingHint)
                        .font(.caption)
                        .foregroundStyle(LoveSongTheme.textTertiary)
                    ForEach(server.lanIPs.dropFirst(), id: \.self) { ip in
                        Text("http://\(ip):\(server.port)")
                            .font(.caption.monospaced())
                            .foregroundStyle(LoveSongTheme.textTertiary)
                            .textSelection(.enabled)
                    }
                    Button {
                        UIPasteboard.general.string = server.publicURLString
                        copied = true
                    } label: {
                        Label(copied ? L10n.copied : L10n.copyURL, systemImage: copied ? "checkmark" : "doc.on.doc")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(LoveSongTheme.spotlight)
                    }
                }
            }
        }
    }

    private var qrCard: some View {
        StageSurface {
            VStack(spacing: 12) {
                Text(L10n.scanQR)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(LoveSongTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let url = server.publicURLString.nilIfEmpty,
                   let uiImage = QRCodeImage.uiImage(from: url) {
                    Image(uiImage: uiImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .padding(12)
                        .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .frame(maxWidth: .infinity)
                }
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
                                .foregroundStyle(task.state == .failed ? .red : LoveSongTheme.textTertiary)
                        }
                        ProgressView(value: task.fraction)
                            .tint(LoveSongTheme.spotlight)
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
        copied = false
    }

    private func byteText(_ value: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: value)
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
