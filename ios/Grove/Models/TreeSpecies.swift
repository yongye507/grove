import Foundation

/// Catalog entry (not persisted as SwiftData — bundled constants).
struct TreeSpecies: Identifiable, Hashable, Sendable {
    let id: String
    /// English source name; use `localizedName` in UI.
    let name: String
    let isFree: Bool
    let assetKey: String

    var localizedName: String {
        String(localized: String.LocalizationValue(name))
    }

    /// Citrus (and similar) show fruit when fully grown.
    var bearsFruit: Bool {
        id == "orange" || id == "lemon"
    }
}

enum TreeCatalog {
    static let all: [TreeSpecies] = [
        .init(id: "oak", name: "Oak", isFree: true, assetKey: "tree_oak"),
        .init(id: "pine", name: "Pine", isFree: true, assetKey: "tree_pine"),
        .init(id: "maple", name: "Maple", isFree: true, assetKey: "tree_maple"),
        .init(id: "ginkgo", name: "Ginkgo", isFree: true, assetKey: "tree_ginkgo"),
        .init(id: "sakura", name: "Sakura", isFree: false, assetKey: "tree_sakura"),
        .init(id: "peony", name: "Peony", isFree: false, assetKey: "tree_peony"),
        .init(id: "orange", name: "Orange", isFree: false, assetKey: "tree_orange"),
        .init(id: "lemon", name: "Lemon", isFree: false, assetKey: "tree_lemon"),
        .init(id: "owl", name: "Owl", isFree: false, assetKey: "tree_owl"),
        .init(id: "fox", name: "Fox", isFree: false, assetKey: "tree_fox"),
        .init(id: "baobab", name: "Baobab", isFree: false, assetKey: "tree_baobab")
    ]

    static func species(id: String) -> TreeSpecies? {
        // Legacy sessions may still store willow / rose.
        let resolved: String = {
            switch id {
            case "willow", "rose": return "peony"
            default: return id
            }
        }()
        return all.first { $0.id == resolved }
    }
}
