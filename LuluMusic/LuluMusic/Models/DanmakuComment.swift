import Foundation
import SwiftData

@Model
final class DanmakuComment {
    @Attribute(.unique) var id: UUID
    var trackId: UUID
    var timestampMS: Int
    var text: String
    var color: String
    var fontSize: Double
    var createdAt: Date

    init(from record: DanmakuRecord) {
        id = record.id
        trackId = record.trackId
        timestampMS = record.timestampMS
        text = record.text
        color = record.color
        fontSize = record.fontSize
        createdAt = record.createdAt
    }

    var asRecord: DanmakuRecord {
        DanmakuRecord(
            id: id,
            trackId: trackId,
            timestampMS: timestampMS,
            text: text,
            color: color,
            fontSize: fontSize,
            createdAt: createdAt
        )
    }
}
