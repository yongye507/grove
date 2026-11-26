import Foundation

/// Catalog entry (not persisted as SwiftData — bundled constants).
struct TreeSpecies: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let isFree: Bool
    let assetKey: String
}

enum TreeCatalog {
    static let all: [TreeSpecies] = [
        .init(id: "oak", name: "Oak", isFree: true, assetKey: "tree_oak"),
        .init(id: "pine", name: "Pine", isFree: true, assetKey: "tree_pine"),
        .init(id: "maple", name: "Maple", isFree: true, assetKey: "tree_maple"),
        .init(id: "sakura", name: "Sakura", isFree: false, assetKey: "tree_sakura"),
        .init(id: "willow", name: "Willow", isFree: false, assetKey: "tree_willow"),
        .init(id: "baobab", name: "Baobab", isFree: false, assetKey: "tree_baobab")
    ]

    static func species(id: String) -> TreeSpecies? {
        all.first { $0.id == id }
    }
}
