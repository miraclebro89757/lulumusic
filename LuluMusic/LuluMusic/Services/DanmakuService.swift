import Foundation
import SwiftData

@MainActor
@Observable
final class DanmakuService: DanmakuStoring {
    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    private var context: ModelContext { container.mainContext }

    func insert(_ record: DanmakuRecord) {
        persistOnBackground(record)
    }

    func persist(_ record: DanmakuRecord) {
        persistOnBackground(record)
    }

    private func persistOnBackground(_ record: DanmakuRecord) {
        let modelContainer = container
        Task.detached(priority: .utility) {
            let context = ModelContext(modelContainer)
            context.insert(DanmakuComment(from: record))
            try? context.save()
        }
    }

    func records(for trackId: UUID) -> [DanmakuRecord] {
        let descriptor = FetchDescriptor<DanmakuComment>(
            predicate: #Predicate { $0.trackId == trackId },
            sortBy: [SortDescriptor(\.timestampMS), SortDescriptor(\.createdAt)]
        )
        return ((try? context.fetch(descriptor)) ?? []).map(\.asRecord)
    }

    func delete(for trackId: UUID) {
        for item in (try? context.fetch(FetchDescriptor<DanmakuComment>(predicate: #Predicate { $0.trackId == trackId }))) ?? [] {
            context.delete(item)
        }
        try? context.save()
    }
}
