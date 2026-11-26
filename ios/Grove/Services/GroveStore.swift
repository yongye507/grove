import Foundation
import SwiftData

enum GroveStore {
    static let presetTags: [(String, String)] = [
        ("Study", "2F6F4E"),
        ("Work", "3D5A80"),
        ("Reading", "8B5E3C"),
        ("Other", "6B7280")
    ]

    @MainActor
    static func bootstrapIfNeeded(context: ModelContext) throws {
        let settings = try context.fetch(FetchDescriptor<AppSettings>())
        if settings.isEmpty {
            context.insert(AppSettings())
        }

        let tags = try context.fetch(FetchDescriptor<FocusTag>())
        if tags.isEmpty {
            for (name, hex) in presetTags {
                context.insert(FocusTag(name: name, colorHex: hex, isPreset: true))
            }
        }

        // Orphaned in-memory sessions after kill/reinstall stay "running" forever.
        let running = try context.fetch(
            FetchDescriptor<FocusSession>(
                predicate: #Predicate { $0.statusRaw == "running" }
            )
        )
        for session in running {
            session.status = .failed
            session.wilted = true
            session.endedAt = session.endedAt ?? .now
        }

        try context.save()
    }

    @MainActor
    static func settings(context: ModelContext) throws -> AppSettings {
        let rows = try context.fetch(FetchDescriptor<AppSettings>())
        if let first = rows.first { return first }
        let created = AppSettings()
        context.insert(created)
        try context.save()
        return created
    }
}
