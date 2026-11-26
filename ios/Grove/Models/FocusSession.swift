import Foundation
import SwiftData

enum SessionStatus: String, Codable, Sendable {
    case running
    case succeeded
    case failed
    case cancelled
}

@Model
final class FocusSession {
    @Attribute(.unique) var id: UUID
    var startedAt: Date
    var durationSec: Int
    var endedAt: Date?
    var statusRaw: String
    var speciesId: String
    var tagId: UUID?
    var leftAppAt: Date?
    var wilted: Bool

    var status: SessionStatus {
        get { SessionStatus(rawValue: statusRaw) ?? .cancelled }
        set { statusRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        startedAt: Date = .now,
        durationSec: Int,
        speciesId: String,
        tagId: UUID? = nil
    ) {
        self.id = id
        self.startedAt = startedAt
        self.durationSec = durationSec
        self.endedAt = nil
        self.statusRaw = SessionStatus.running.rawValue
        self.speciesId = speciesId
        self.tagId = tagId
        self.leftAppAt = nil
        self.wilted = false
    }

    var plannedEndAt: Date {
        startedAt.addingTimeInterval(TimeInterval(durationSec))
    }

    func remaining(at now: Date = .now) -> TimeInterval {
        max(0, plannedEndAt.timeIntervalSince(now))
    }
}
