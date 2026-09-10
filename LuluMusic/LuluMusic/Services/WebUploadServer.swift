import Foundation
import Network
import UIKit

struct UploadTask: Identifiable, Equatable {
    enum State: String {
        case receiving
        case importing
        case done
        case failed
    }

    let id: UUID
    var fileName: String
    var bytesReceived: Int64
    var totalBytes: Int64
    var state: State
    var message: String?

    var fraction: Double {
        guard totalBytes > 0 else { return state == .done ? 1 : 0 }
        return min(1, Double(bytesReceived) / Double(totalBytes))
    }
}

/// Lightweight HTTP/1.1 listener for same-LAN browser uploads. No third-party server.
@MainActor
@Observable
final class WebUploadServer {
    var isRunning = false
    var port: UInt16 = 8787
    var token = ""
    var lanIPs: [String] = []
    var tasks: [UploadTask] = []
    var lastError: String?
    var statusText = L10n.serverStopped

    var onFileReady: ((URL, String) async throws -> Void)?

    var publicURL: URL? {
        guard isRunning, let ip = lanIPs.first else { return nil }
        return URL(string: "http://\(ip):\(port)/t/\(token)/")
    }

    var publicURLString: String {
        publicURL?.absoluteString ?? ""
    }

    private var engine: HTTPListenerEngine?

    func start() {
        stop()
        lastError = nil
        token = Self.makeToken()
        lanIPs = LocalIPAddress.lanIPv4Addresses()
        let engine = HTTPListenerEngine(preferredPort: 8787)
        self.engine = engine

        engine.onReady = { [weak self] port in
            Task { @MainActor in
                guard let self else { return }
                self.port = port
                self.isRunning = true
                self.statusText = L10n.serverRunning
                self.lanIPs = LocalIPAddress.lanIPv4Addresses()
                UIApplication.shared.isIdleTimerDisabled = true
            }
        }
        engine.onFailed = { [weak self] message in
            Task { @MainActor in
                self?.lastError = message
                self?.isRunning = false
                self?.statusText = L10n.serverStopped
                UIApplication.shared.isIdleTimerDisabled = false
            }
        }
        engine.onProgress = { [weak self] update in
            Task { @MainActor in
                self?.apply(update)
            }
        }
        engine.onFileReceived = { [weak self] fileURL, fileName, taskID in
            Task { @MainActor in
                await self?.finishImport(fileURL: fileURL, fileName: fileName, taskID: taskID)
            }
        }
        engine.token = token
        engine.start()
    }

    func stop() {
        engine?.stop()
        engine = nil
        isRunning = false
        statusText = L10n.serverStopped
        UIApplication.shared.isIdleTimerDisabled = false
    }

    private func finishImport(fileURL: URL, fileName: String, taskID: UUID) async {
        update(taskID) { task in
            task.state = .importing
            task.message = L10n.importing
        }
        do {
            guard let onFileReady else { throw LibraryError.copyFailed }
            try await onFileReady(fileURL, fileName)
            update(taskID) { task in
                task.state = .done
                task.message = L10n.importSuccess
                task.bytesReceived = max(task.bytesReceived, task.totalBytes)
            }
        } catch {
            update(taskID) { task in
                task.state = .failed
                task.message = error.localizedDescription
            }
        }
        try? FileManager.default.removeItem(at: fileURL)
    }

    private func apply(_ update: HTTPListenerEngine.ProgressUpdate) {
        if let idx = tasks.firstIndex(where: { $0.id == update.id }) {
            tasks[idx].fileName = update.fileName
            tasks[idx].bytesReceived = update.received
            tasks[idx].totalBytes = update.total
            if tasks[idx].state == .receiving {
                tasks[idx].message = L10n.receiving
            }
            if update.failed {
                tasks[idx].state = .failed
                tasks[idx].message = update.message ?? L10n.failed
            }
        } else {
            tasks.insert(
                UploadTask(
                    id: update.id,
                    fileName: update.fileName,
                    bytesReceived: update.received,
                    totalBytes: update.total,
                    state: update.failed ? .failed : .receiving,
                    message: update.failed ? (update.message ?? L10n.failed) : L10n.receiving
                ),
                at: 0
            )
        }
    }

    private func update(_ id: UUID, mutate: (inout UploadTask) -> Void) {
        guard let idx = tasks.firstIndex(where: { $0.id == id }) else { return }
        mutate(&tasks[idx])
    }

    private static func makeToken() -> String {
        let chars = Array("abcdefghjkmnpqrstuvwxyz23456789")
        return String((0..<6).map { _ in chars.randomElement()! })
    }
}

// MARK: - Listener

final class HTTPListenerEngine: @unchecked Sendable {
    struct ProgressUpdate: Sendable {
        var id: UUID
        var fileName: String
        var received: Int64
        var total: Int64
        var failed: Bool
        var message: String?
    }

    var token = ""
    var onReady: ((UInt16) -> Void)?
    var onFailed: ((String) -> Void)?
    var onProgress: ((ProgressUpdate) -> Void)?
    var onFileReceived: ((URL, String, UUID) -> Void)?

    private let preferredPort: UInt16
    private var listener: NWListener?
    private let queue = DispatchQueue(label: "com.lulumusic.webupload", qos: .userInitiated)
    private var connections: [ObjectIdentifier: HTTPConnection] = [:]

    init(preferredPort: UInt16) {
        self.preferredPort = preferredPort
    }

    func start() {
        do {
            try bind(port: preferredPort)
        } catch {
            do {
                try bind(port: 0)
            } catch {
                onFailed?("无法启动局域网服务：\(error.localizedDescription)")
            }
        }
    }

    func stop() {
        queue.async { [weak self] in
            guard let self else { return }
            self.listener?.cancel()
            self.listener = nil
            self.connections.values.forEach { $0.cancel() }
            self.connections.removeAll()
        }
    }

    private func bind(port: UInt16) throws {
        let parameters = NWParameters.tcp
        parameters.allowLocalEndpointReuse = true
        let nwPort = NWEndpoint.Port(rawValue: port) ?? .any
        let listener = try NWListener(using: parameters, on: nwPort)
        self.listener = listener

        listener.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            switch state {
            case .ready:
                let actual = self.listener?.port?.rawValue ?? port
                self.onReady?(actual)
            case .failed(let error):
                self.onFailed?(error.localizedDescription)
            default:
                break
            }
        }

        listener.newConnectionHandler = { [weak self] connection in
            self?.accept(connection)
        }
        listener.start(queue: queue)
    }

    private func accept(_ connection: NWConnection) {
        let http = HTTPConnection(connection: connection, token: token, engine: self)
        connections[ObjectIdentifier(http)] = http
        http.onClose = { [weak self, weak http] in
            guard let self, let http else { return }
            self.connections[ObjectIdentifier(http)] = nil
        }
        http.start()
    }

    fileprivate func report(_ update: ProgressUpdate) {
        onProgress?(update)
    }

    fileprivate func finished(fileURL: URL, fileName: String, taskID: UUID) {
        onFileReceived?(fileURL, fileName, taskID)
    }
}

// MARK: - Connection

private final class HTTPConnection: @unchecked Sendable {
    var onClose: (() -> Void)?

    private let connection: NWConnection
    private let token: String
    private weak var engine: HTTPListenerEngine?
    private var headerData = Data()
    private var headersParsed = false
    private var bodyHandler: BodyHandler?
    private var cancelled = false

    init(connection: NWConnection, token: String, engine: HTTPListenerEngine) {
        self.connection = connection
        self.token = token
        self.engine = engine
    }

    func start() {
        connection.stateUpdateHandler = { [weak self] state in
            if case .failed = state { self?.cancel() }
            if case .cancelled = state { self?.finishClose() }
        }
        connection.start(queue: .global(qos: .userInitiated))
        receive()
    }

    func cancel() {
        cancelled = true
        bodyHandler?.fail("连接中断")
        connection.cancel()
        finishClose()
    }

    private func finishClose() {
        onClose?()
        onClose = nil
    }

    private func receive() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 64 * 1024) { [weak self] data, _, isComplete, error in
            guard let self, !self.cancelled else { return }
            if let error {
                self.bodyHandler?.fail(error.localizedDescription)
                self.cancel()
                return
            }
            if let data, !data.isEmpty {
                self.ingest(data)
            }
            if isComplete {
                self.bodyHandler?.completeIfPossible()
                self.connection.cancel()
                self.finishClose()
                return
            }
            self.receive()
        }
    }

    private func ingest(_ data: Data) {
        if !headersParsed {
            headerData.append(data)
            guard let range = headerData.range(of: Data("\r\n\r\n".utf8)) else {
                if headerData.count > 64 * 1024 {
                    send(status: 413, contentType: "text/plain", body: Data("headers too large".utf8))
                    cancel()
                }
                return
            }
            let headerBlock = headerData.subdata(in: headerData.startIndex..<range.lowerBound)
            let remainder = headerData.subdata(in: range.upperBound..<headerData.endIndex)
            headersParsed = true
            headerData = Data()
            handleHeaders(headerBlock, remainder: remainder)
        } else {
            bodyHandler?.append(data)
        }
    }

    private func handleHeaders(_ raw: Data, remainder: Data) {
        guard let text = String(data: raw, encoding: .isoLatin1) else {
            send(status: 400, contentType: "text/plain", body: Data("bad request".utf8))
            return
        }
        let lines = text.split(separator: "\r\n", omittingEmptySubsequences: false).map(String.init)
        guard let requestLine = lines.first else {
            send(status: 400, contentType: "text/plain", body: Data("bad request".utf8))
            return
        }
        let parts = requestLine.split(separator: " ")
        guard parts.count >= 2 else {
            send(status: 400, contentType: "text/plain", body: Data("bad request".utf8))
            return
        }
        let method = String(parts[0]).uppercased()
        let path = String(parts[1])

        var headerMap: [String: String] = [:]
        for line in lines.dropFirst() {
            guard let colon = line.firstIndex(of: ":") else { continue }
            let key = line[..<colon].trimmingCharacters(in: .whitespaces).lowercased()
            let value = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
            headerMap[key] = value
        }

        route(method: method, path: path, headers: headerMap, remainder: remainder)
    }

    private func route(method: String, path: String, headers: [String: String], remainder: Data) {
        let prefix = "/t/\(token)"
        if method == "OPTIONS" {
            send(status: 204, contentType: "text/plain", body: Data(), extra: ["Access-Control-Allow-Origin": "*"])
            return
        }

        if path == "/" || path == "/index.html" {
            let html = UploadPageHTML.document(token: token)
            send(status: 200, contentType: "text/html; charset=utf-8", body: Data(html.utf8))
            return
        }

        guard path == prefix || path.hasPrefix(prefix + "/") || path.hasPrefix(prefix + "?") else {
            send(status: 404, contentType: "text/plain; charset=utf-8", body: Data("未找到。请使用手机上显示的完整链接。".utf8))
            return
        }

        let rest: String
        if path == prefix || path == prefix + "/" {
            rest = "/"
        } else {
            rest = String(path.dropFirst(prefix.count))
        }

        if method == "GET" && (rest == "/" || rest.hasPrefix("/?") || rest == "/index.html") {
            let html = UploadPageHTML.document(token: token)
            send(status: 200, contentType: "text/html; charset=utf-8", body: Data(html.utf8))
            return
        }

        if method == "POST" && (rest.hasPrefix("/upload") || rest == "/upload") {
            beginUpload(path: rest, headers: headers, remainder: remainder)
            return
        }

        send(status: 404, contentType: "text/plain", body: Data("not found".utf8))
    }

    private func beginUpload(path: String, headers: [String: String], remainder: Data) {
        try? LibraryPaths.ensureDirectories()
        let contentType = headers["content-type"] ?? "application/octet-stream"
        let length = Int64(headers["content-length"] ?? "") ?? -1
        let queryName = queryItem(named: "filename", in: path)
        let headerName = headers["x-file-name"].flatMap { $0.removingPercentEncoding }
        let fileName = sanitizedFileName(queryName ?? headerName ?? "upload.mp3")
        let taskID = UUID()
        let dest = LibraryPaths.uploadTempDirectory.appendingPathComponent("\(taskID.uuidString)-\(fileName)")

        engine?.report(.init(id: taskID, fileName: fileName, received: 0, total: max(0, length), failed: false, message: nil))

        if contentType.lowercased().contains("multipart/form-data") {
            guard let boundary = multipartBoundary(from: contentType) else {
                send(status: 400, contentType: "text/plain", body: Data("missing boundary".utf8))
                return
            }
            let handler = MultipartBodyHandler(
                boundary: boundary,
                dest: dest,
                fallbackName: fileName,
                taskID: taskID,
                expected: length,
                engine: engine,
                connection: self
            )
            bodyHandler = handler
            handler.append(remainder)
            return
        }

        let handler = RawBodyHandler(
            dest: dest,
            fileName: fileName,
            taskID: taskID,
            expected: length,
            engine: engine,
            connection: self
        )
        bodyHandler = handler
        handler.append(remainder)
    }

    fileprivate func send(status: Int, contentType: String, body: Data, extra: [String: String] = [:]) {
        var header = "HTTP/1.1 \(status) \(HTTPListenerEngine.statusText(status))\r\n"
        header += "Content-Type: \(contentType)\r\n"
        header += "Content-Length: \(body.count)\r\n"
        header += "Connection: close\r\n"
        header += "Access-Control-Allow-Origin: *\r\n"
        header += "Access-Control-Allow-Methods: GET, POST, OPTIONS\r\n"
        header += "Access-Control-Allow-Headers: Content-Type, X-File-Name\r\n"
        for (k, v) in extra {
            header += "\(k): \(v)\r\n"
        }
        header += "\r\n"
        var payload = Data(header.utf8)
        payload.append(body)
        connection.send(content: payload, completion: .contentProcessed { [weak self] _ in
            self?.connection.cancel()
            self?.finishClose()
        })
    }

    fileprivate func completeUpload(taskID: UUID, fileURL: URL, fileName: String) {
        engine?.finished(fileURL: fileURL, fileName: fileName, taskID: taskID)
        let json = "{\"ok\":true,\"file\":\"\(fileName)\"}"
        send(status: 200, contentType: "application/json; charset=utf-8", body: Data(json.utf8))
    }

    fileprivate func failUpload(message: String) {
        send(status: 500, contentType: "text/plain; charset=utf-8", body: Data(message.utf8))
    }

    private func queryItem(named name: String, in path: String) -> String? {
        guard let q = path.split(separator: "?").dropFirst().first else { return nil }
        for pair in q.split(separator: "&") {
            let kv = pair.split(separator: "=", maxSplits: 1).map(String.init)
            guard kv.count == 2, kv[0] == name else { continue }
            return kv[1].removingPercentEncoding ?? kv[1]
        }
        return nil
    }

    private func multipartBoundary(from contentType: String) -> String? {
        let parts = contentType.split(separator: ";")
        for part in parts {
            let trimmed = part.trimmingCharacters(in: .whitespaces)
            if trimmed.lowercased().hasPrefix("boundary=") {
                var value = String(trimmed.dropFirst("boundary=".count))
                if value.hasPrefix("\"") && value.hasSuffix("\"") {
                    value = String(value.dropFirst().dropLast())
                }
                return value
            }
        }
        return nil
    }

    private func sanitizedFileName(_ name: String) -> String {
        let last = URL(fileURLWithPath: name).lastPathComponent
        let cleaned = last.replacingOccurrences(of: "/", with: "-")
        return cleaned.isEmpty ? "upload.mp3" : cleaned
    }
}

private protocol BodyHandler: AnyObject {
    func append(_ data: Data)
    func completeIfPossible()
    func fail(_ message: String)
}

private final class RawBodyHandler: BodyHandler {
    private let dest: URL
    private let fileName: String
    private let taskID: UUID
    private let expected: Int64
    private weak var engine: HTTPListenerEngine?
    private weak var connection: HTTPConnection?
    private var handle: FileHandle?
    private var received: Int64 = 0
    private var finished = false

    init(
        dest: URL,
        fileName: String,
        taskID: UUID,
        expected: Int64,
        engine: HTTPListenerEngine?,
        connection: HTTPConnection
    ) {
        self.dest = dest
        self.fileName = fileName
        self.taskID = taskID
        self.expected = expected
        self.engine = engine
        self.connection = connection
        FileManager.default.createFile(atPath: dest.path, contents: nil)
        handle = try? FileHandle(forWritingTo: dest)
    }

    func append(_ data: Data) {
        guard !finished, !data.isEmpty else {
            if expected == 0 || (expected < 0 && !finished && received == 0 && data.isEmpty) {
                completeIfPossible()
            }
            return
        }
        handle?.write(data)
        received += Int64(data.count)
        engine?.report(.init(id: taskID, fileName: fileName, received: received, total: expected, failed: false, message: nil))
        if expected > 0 && received >= expected {
            completeIfPossible()
        }
    }

    func completeIfPossible() {
        guard !finished else { return }
        finished = true
        try? handle?.close()
        handle = nil
        connection?.completeUpload(taskID: taskID, fileURL: dest, fileName: fileName)
    }

    func fail(_ message: String) {
        guard !finished else { return }
        finished = true
        try? handle?.close()
        try? FileManager.default.removeItem(at: dest)
        engine?.report(.init(id: taskID, fileName: fileName, received: received, total: expected, failed: true, message: message))
        connection?.failUpload(message: message)
    }
}

private final class MultipartBodyHandler: BodyHandler {
    private let dest: URL
    private var fileName: String
    private let taskID: UUID
    private let expected: Int64
    private weak var engine: HTTPListenerEngine?
    private weak var connection: HTTPConnection?
    private let boundaryData: Data
    private let endBoundaryData: Data
    private var buffer = Data()
    private var handle: FileHandle?
    private var writingFile = false
    private var finished = false
    private var receivedTotal: Int64 = 0
    private var wroteBytes: Int64 = 0

    init(
        boundary: String,
        dest: URL,
        fallbackName: String,
        taskID: UUID,
        expected: Int64,
        engine: HTTPListenerEngine?,
        connection: HTTPConnection
    ) {
        self.dest = dest
        self.fileName = fallbackName
        self.taskID = taskID
        self.expected = expected
        self.engine = engine
        self.connection = connection
        self.boundaryData = Data("\r\n--\(boundary)".utf8)
        self.endBoundaryData = Data("\r\n--\(boundary)--".utf8)
        FileManager.default.createFile(atPath: dest.path, contents: nil)
        handle = try? FileHandle(forWritingTo: dest)
    }

    func append(_ data: Data) {
        guard !finished else { return }
        receivedTotal += Int64(data.count)
        buffer.append(data)
        // First MIME part starts with --boundary, not CRLF--boundary.
        if !writingFile, buffer.starts(with: Data("--".utf8)) {
            buffer.insert(contentsOf: Data("\r\n".utf8), at: buffer.startIndex)
        }
        processBuffer()
        engine?.report(.init(id: taskID, fileName: fileName, received: receivedTotal, total: expected, failed: false, message: nil))
    }

    func completeIfPossible() {
        processBuffer(force: true)
        finishSuccess()
    }

    func fail(_ message: String) {
        guard !finished else { return }
        finished = true
        try? handle?.close()
        try? FileManager.default.removeItem(at: dest)
        engine?.report(.init(id: taskID, fileName: fileName, received: receivedTotal, total: expected, failed: true, message: message))
        connection?.failUpload(message: message)
    }

    private func processBuffer(force: Bool = false) {
        if !writingFile {
            if let headerEnd = buffer.range(of: Data("\r\n\r\n".utf8)) {
                let headerText = String(data: buffer.subdata(in: buffer.startIndex..<headerEnd.lowerBound), encoding: .isoLatin1) ?? ""
                if let name = filenameFromPartHeaders(headerText) {
                    fileName = name
                }
                buffer.removeSubrange(buffer.startIndex..<headerEnd.upperBound)
                writingFile = true
            } else {
                return
            }
        }

        let keep = boundaryData.count + 8
        while buffer.count > keep {
            if let range = buffer.range(of: boundaryData) ?? buffer.range(of: endBoundaryData) {
                let fileSlice = buffer.subdata(in: buffer.startIndex..<range.lowerBound)
                if !fileSlice.isEmpty {
                    handle?.write(fileSlice)
                    wroteBytes += Int64(fileSlice.count)
                }
                buffer.removeAll()
                finishSuccess()
                return
            }
            let flushCount = buffer.count - keep
            let start = buffer.startIndex
            let flushEnd = buffer.index(start, offsetBy: flushCount)
            handle?.write(buffer.subdata(in: start..<flushEnd))
            wroteBytes += Int64(flushCount)
            buffer.removeSubrange(start..<flushEnd)
        }

        if force, !buffer.isEmpty {
            if let range = buffer.range(of: boundaryData) ?? buffer.range(of: endBoundaryData) {
                let fileSlice = buffer.subdata(in: buffer.startIndex..<range.lowerBound)
                handle?.write(fileSlice)
                wroteBytes += Int64(fileSlice.count)
            }
            finishSuccess()
        }
    }

    private func finishSuccess() {
        guard !finished else { return }
        finished = true
        try? handle?.close()
        handle = nil
        connection?.completeUpload(taskID: taskID, fileURL: dest, fileName: fileName)
    }

    private func filenameFromPartHeaders(_ headers: String) -> String? {
        for line in headers.split(separator: "\r\n") {
            if let name = extractFilename(from: String(line)) {
                return name
            }
        }
        return nil
    }

    private func extractFilename(from disposition: String) -> String? {
        guard let marker = disposition.range(of: "filename=", options: .caseInsensitive) else { return nil }
        var rest = String(disposition[marker.upperBound...])
        if rest.hasPrefix("\"") {
            rest.removeFirst()
            if let end = rest.firstIndex(of: "\"") {
                rest = String(rest[..<end])
            }
        } else {
            rest = rest.split(separator: ";").first.map(String.init) ?? rest
        }
        let decoded = rest.removingPercentEncoding ?? rest
        let base = URL(fileURLWithPath: decoded).lastPathComponent
        return base.isEmpty ? nil : base
    }
}

extension HTTPListenerEngine {
    static func statusText(_ code: Int) -> String {
        switch code {
        case 200: return "OK"
        case 204: return "No Content"
        case 400: return "Bad Request"
        case 404: return "Not Found"
        case 413: return "Payload Too Large"
        case 500: return "Internal Server Error"
        default: return "OK"
        }
    }
}

enum UploadPageHTML {
    static func document(token: String) -> String {
        """
        <!doctype html>
        <html lang="zh-CN">
        <head>
        <meta charset="utf-8"/>
        <meta name="viewport" content="width=device-width, initial-scale=1"/>
        <title>陆陆音乐 · 上传</title>
        <style>
          :root { color-scheme: dark; }
          * { box-sizing: border-box; }
          body {
            margin: 0; min-height: 100vh; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
            background: radial-gradient(1200px 800px at 10% -10%, #5b2a6e 0%, transparent 50%),
                        radial-gradient(900px 700px at 110% 10%, #c23d6e 0%, transparent 46%),
                        #0c0b10;
            color: #f6f3f7; display: flex; align-items: center; justify-content: center; padding: 32px 16px;
          }
          .card {
            width: min(560px, 100%); background: rgba(22,20,28,.86); border: 1px solid rgba(255,255,255,.08);
            border-radius: 28px; padding: 28px; box-shadow: 0 30px 80px rgba(0,0,0,.35); backdrop-filter: blur(16px);
          }
          h1 { margin: 0 0 6px; font-size: 28px; letter-spacing: .02em; }
          p.sub { margin: 0 0 22px; color: #c9c0cc; line-height: 1.5; }
          .drop {
            border: 1.5px dashed rgba(255,180,200,.45); border-radius: 20px; padding: 36px 16px; text-align: center;
            background: rgba(255,255,255,.03); cursor: pointer; transition: .2s ease;
          }
          .drop.drag { border-color: #e8507a; background: rgba(232,80,122,.12); }
          input[type=file] { display: none; }
          button {
            margin-top: 16px; width: 100%; border: 0; border-radius: 14px; padding: 14px 16px;
            background: linear-gradient(90deg,#c23d6e,#8a3d9b); color: white; font-size: 16px; font-weight: 600; cursor: pointer;
          }
          .row { margin-top: 14px; padding: 10px 0; border-bottom: 1px solid rgba(255,255,255,.06); font-size: 14px; }
          .bar { height: 6px; border-radius: 99px; background: #2a2630; overflow: hidden; margin-top: 6px; }
          .bar > i { display: block; height: 100%; width: 0; background: linear-gradient(90deg,#ff7aa2,#c23d6e); }
          .ok { color: #8ee0b2; } .err { color: #ff9aa8; }
          .hint { margin-top: 18px; color: #9b93a3; font-size: 12px; }
        </style>
        </head>
        <body>
        <div class="card">
          <h1>陆陆音乐</h1>
          <p class="sub">把电脑上的 mp3 / m4a / aac / wav / flac 拖到这里，歌曲会拷进手机曲库，可离线播放。</p>
          <label class="drop" id="drop">
            点击或拖放音频文件<br/><small>可一次选择多首</small>
            <input id="file" type="file" multiple accept="audio/*,.mp3,.m4a,.aac,.wav,.flac,.aiff"/>
          </label>
          <form id="fallback" method="post" action="/t/\(token)/upload" enctype="multipart/form-data">
            <button type="submit">开始上传</button>
          </form>
          <div id="list"></div>
          <p class="hint">LuluMusic local upload · token \(token) · keep the iPhone screen on this page.</p>
        </div>
        <script>
        const drop = document.getElementById('drop');
        const input = document.getElementById('file');
        const list = document.getElementById('list');
        const fallback = document.getElementById('fallback');
        const allowed = ['mp3','m4a','aac','wav','flac','aiff','aif','caf'];

        function ext(name){ return (name.split('.').pop() || '').toLowerCase(); }
        function row(name){
          const el = document.createElement('div');
          el.className = 'row';
          el.innerHTML = '<div class="name"></div><div class="bar"><i></i></div><div class="msg"></div>';
          el.querySelector('.name').textContent = name;
          list.prepend(el);
          return el;
        }
        function upload(file){
          const el = row(file.name);
          const bar = el.querySelector('i');
          const msg = el.querySelector('.msg');
          if (!allowed.includes(ext(file.name))) {
            msg.className = 'msg err';
            msg.textContent = '不支持的格式';
            return;
          }
          const xhr = new XMLHttpRequest();
          xhr.open('POST', '/t/\(token)/upload?filename=' + encodeURIComponent(file.name));
          xhr.setRequestHeader('Content-Type', file.type || 'application/octet-stream');
          xhr.setRequestHeader('X-File-Name', encodeURIComponent(file.name));
          xhr.upload.onprogress = (e) => {
            if (e.lengthComputable) bar.style.width = Math.round(e.loaded / e.total * 100) + '%';
          };
          xhr.onload = () => {
            if (xhr.status >= 200 && xhr.status < 300) {
              bar.style.width = '100%';
              msg.className = 'msg ok';
              msg.textContent = '已传到手机';
            } else {
              msg.className = 'msg err';
              msg.textContent = '失败：' + xhr.responseText;
            }
          };
          xhr.onerror = () => { msg.className = 'msg err'; msg.textContent = '网络错误'; };
          xhr.send(file);
        }
        function take(files){ [...files].forEach(upload); }
        drop.addEventListener('dragover', e => { e.preventDefault(); drop.classList.add('drag'); });
        drop.addEventListener('dragleave', () => drop.classList.remove('drag'));
        drop.addEventListener('drop', e => { e.preventDefault(); drop.classList.remove('drag'); take(e.dataTransfer.files); });
        input.addEventListener('change', () => take(input.files));
        fallback.addEventListener('submit', e => {
          if (input.files && input.files.length) {
            e.preventDefault();
            take(input.files);
          }
        });
        </script>
        </body>
        </html>
        """
    }
}
