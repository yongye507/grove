import SwiftUI

/// Plant-page wrapper around shared `TreeArt` (keeps call sites stable).
struct TreeGrowthView: View {
    var progress: Double
    var wilted: Bool
    var speciesName: String
    var speciesId: String = "oak"
    var compact: Bool = false

    private var clamped: Double { min(max(progress, 0), 1) }
    private var stage: TreeStage { .from(progress: clamped, wilted: wilted) }
    /// Soft fruit appear near the end of a session for citrus species.
    private var fruitBloom: Double {
        guard TreeCatalog.species(id: speciesId)?.bearsFruit == true, !wilted else { return 0 }
        return min(1, max(0, (clamped - 0.88) / 0.12))
    }

    var body: some View {
        TreeArt(
            speciesId: speciesId,
            progress: clamped,
            wilted: wilted,
            size: compact ? .bed : .hero,
            fruitBloom: fruitBloom
        )
        // Don't clip here — parents that need a hard edge (timer pane / outcome card)
        // apply their own clip. Extra clip here shaved canopy into empty top padding.
        .animation(.easeInOut(duration: 0.55), value: clamped)
        .animation(.easeInOut(duration: 0.45), value: wilted)
        .accessibilityLabel("\(speciesName), \(stage.localizedTitle)")
    }
}
