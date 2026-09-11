import Foundation

struct DanmakuRecord: Equatable, Identifiable, Codable, Hashable {
    var id: UUID
    var trackId: UUID
    var timestampMS: Int
    var text: String
    var color: String
    var fontSize: Double
    var createdAt: Date

    init(
        id: UUID = UUID(),
        trackId: UUID,
        timestampMS: Int,
        text: String,
        color: String = "#FFFFFF",
        fontSize: Double = 16,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.trackId = trackId
        self.timestampMS = max(0, timestampMS)
        self.text = text
        self.color = color
        self.fontSize = fontSize
        self.createdAt = createdAt
    }
}

struct FlyingDanmaku: Equatable, Identifiable {
    var id: UUID { record.id }
    var record: DanmakuRecord
    var lane: Int
    var spawnTimeMS: Int
    var isLiveSend: Bool
    var fading: Bool
    var spawnedAt: Date
}

struct DanmakuScheduler: Equatable {
    var spawnLeadMS: Int = 500
    var timingToleranceMS: Int = 300
    var maxLanes: Int = 3
    var densityCap: Int = 5
    var sendAppearBudgetMS: Int = 100

    func replaySpawnTimeMS(for record: DanmakuRecord) -> Int {
        max(0, record.timestampMS - spawnLeadMS)
    }

    /// After flying for `spawnLeadMS`, the bullet should be over the cover near `timestampMS`.
    func expectedDisplayTimeMS(for record: DanmakuRecord) -> Int {
        replaySpawnTimeMS(for: record) + min(spawnLeadMS, record.timestampMS)
    }

    func isWithinTimingTolerance(displayTimeMS: Int, record: DanmakuRecord) -> Bool {
        abs(displayTimeMS - record.timestampMS) <= timingToleranceMS
    }

    func shouldSpawnReplay(record: DanmakuRecord, currentTimeMS: Int, alreadySpawned: Set<UUID>) -> Bool {
        guard !alreadySpawned.contains(record.id) else { return false }
        return currentTimeMS >= replaySpawnTimeMS(for: record)
    }

    func assignLane(existing: [FlyingDanmaku]) -> Int {
        let lanes = max(1, min(3, maxLanes))
        var counts = Array(repeating: 0, count: lanes)
        for item in existing where !item.fading {
            if item.lane >= 0 && item.lane < lanes {
                counts[item.lane] += 1
            }
        }
        return counts.enumerated().min(by: { $0.element < $1.element })?.offset ?? 0
    }
}

protocol DanmakuStoring: AnyObject {
    func insert(_ record: DanmakuRecord)
    func records(for trackId: UUID) -> [DanmakuRecord]
}

final class InMemoryDanmakuStore: DanmakuStoring {
    private var items: [DanmakuRecord] = []

    func insert(_ record: DanmakuRecord) {
        items.append(record)
    }

    func records(for trackId: UUID) -> [DanmakuRecord] {
        items
            .filter { $0.trackId == trackId }
            .sorted { lhs, rhs in
                if lhs.timestampMS != rhs.timestampMS { return lhs.timestampMS < rhs.timestampMS }
                return lhs.createdAt < rhs.createdAt
            }
    }
}

/// Send + replay orchestrator. Pure (no UI). F06 / F07.
struct DanmakuRuntime {
    var store: DanmakuStoring
    var scheduler: DanmakuScheduler
    var flying: [FlyingDanmaku] = []
    var spawnedIDs: Set<UUID> = []
    var enabled: Bool = true
    private var catalog: [DanmakuRecord] = []
    private var catalogLoaded = false

    init(store: DanmakuStoring, scheduler: DanmakuScheduler = DanmakuScheduler()) {
        self.store = store
        self.scheduler = scheduler
    }

    mutating func resetTrack() {
        flying = []
        spawnedIDs = []
        catalog = []
        catalogLoaded = false
    }

    /// Optimistic fly: enqueue on the hot path only. Persist separately.
    @discardableResult
    mutating func send(trackId: UUID, text: String, currentTimeMS: Int, now: Date = Date()) -> DanmakuRecord? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard enabled, !trimmed.isEmpty else { return nil }
        let record = DanmakuRecord(trackId: trackId, timestampMS: currentTimeMS, text: trimmed, createdAt: now)
        catalog.append(record)
        spawn(record, at: currentTimeMS, live: true)
        return record
    }

    mutating func tick(trackId: UUID, currentTimeMS: Int) {
        guard enabled else { return }
        ensureCatalog(trackId: trackId)
        for record in catalog where scheduler.shouldSpawnReplay(
            record: record,
            currentTimeMS: currentTimeMS,
            alreadySpawned: spawnedIDs
        ) {
            spawn(record, at: currentTimeMS, live: false)
        }
        applyDensityCap()
    }

    mutating func persist(_ record: DanmakuRecord) {
        store.insert(record)
    }

    private mutating func ensureCatalog(trackId: UUID) {
        guard !catalogLoaded else { return }
        let pending = catalog
        catalog = store.records(for: trackId)
        let seen = Set(catalog.map(\.id))
        for record in pending where !seen.contains(record.id) {
            catalog.append(record)
        }
        catalogLoaded = true
    }

    private mutating func spawn(_ record: DanmakuRecord, at timeMS: Int, live: Bool) {
        guard !spawnedIDs.contains(record.id) else { return }
        let lane = scheduler.assignLane(existing: flying)
        flying.append(
            FlyingDanmaku(
                record: record,
                lane: lane,
                spawnTimeMS: timeMS,
                isLiveSend: live,
                fading: false,
                spawnedAt: Date()
            )
        )
        spawnedIDs.insert(record.id)
        applyDensityCap()
    }

    mutating func applyDensityCap() {
        let active = flying.filter { !$0.fading }
        guard active.count > scheduler.densityCap else { return }
        let overflow = active.count - scheduler.densityCap
        let toFade = Set(active.prefix(overflow).map(\.id))
        for i in flying.indices {
            if toFade.contains(flying[i].id) {
                flying[i].fading = true
            }
        }
    }
}
