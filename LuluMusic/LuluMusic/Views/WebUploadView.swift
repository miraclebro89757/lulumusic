import SwiftUI
import UIKit

struct WebUploadView: View {
    @Environment(LibraryService.self) private var library
    @State private var server = WebUploadServer()
    @State private var copied = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(L10n.webUploadHint)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(L10n.keepForeground)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                statusCard
                if server.isRunning {
                    addressCard
                    qrCard
                }
                uploadsCard
            }
            .padding(16)
            .padding(.bottom, 40)
        }
        .navigationTitle(L10n.webUploadTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(server.isRunning ? L10n.stopServer : L10n.startServer) {
                    if server.isRunning {
                        server.stop()
                    } else {
                        startServer()
                    }
                }
            }
        }
        .onAppear { startServer() }
        .onDisappear { server.stop() }
    }

    private var statusCard: some View {
        HStack {
            Circle()
                .fill(server.isRunning ? Color.green : Color.secondary)
                .frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 2) {
                Text(server.statusText)
                    .font(.headline)
                if let error = server.lastError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                } else if server.lanIPs.isEmpty && server.isRunning {
                    Text(L10n.noWiFi)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            Spacer()
        }
        .padding(16)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var addressCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.lanAddress)
                .font(.headline)
            if server.publicURLString.isEmpty {
                Text(L10n.noWiFi)
                    .foregroundStyle(.secondary)
            } else {
                Text(server.publicURLString)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                ForEach(server.lanIPs.dropFirst(), id: \.self) { ip in
                    Text("http://\(ip):\(server.port)/t/\(server.token)/")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
                Button {
                    UIPasteboard.general.string = server.publicURLString
                    copied = true
                } label: {
                    Label(copied ? L10n.copied : L10n.copyURL, systemImage: copied ? "checkmark" : "doc.on.doc")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var qrCard: some View {
        VStack(spacing: 12) {
            Text(L10n.scanQR)
                .font(.headline)
            if let url = server.publicURLString.nilIfEmpty,
               let uiImage = QRCodeImage.uiImage(from: url) {
                Image(uiImage: uiImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220, height: 220)
                    .padding(12)
                    .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var uploadsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(server.tasks.isEmpty ? L10n.waitingUpload : L10n.receiving)
                .font(.headline)
            if server.tasks.isEmpty {
                Text("电脑浏览器打开链接后，将音频拖进页面即可。进度会显示在这里。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            ForEach(server.tasks) { task in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(task.fileName)
                            .lineLimit(1)
                        Spacer()
                        Text(task.message ?? "")
                            .font(.caption)
                            .foregroundStyle(task.state == .failed ? .red : .secondary)
                    }
                    ProgressView(value: task.fraction)
                    if task.totalBytes > 0 {
                        Text("\(byteText(task.bytesReceived)) / \(byteText(task.totalBytes))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
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
