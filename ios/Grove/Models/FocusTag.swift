import Foundation
import SwiftData

@Model
final class FocusTag {
    @Attribute(.unique) var id: UUID
    var name: String
    var colorHex: String
    var isPreset: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        colorHex: String = "2F6F4E",
        isPreset: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.isPreset = isPreset
        self.createdAt = createdAt
    }
}
