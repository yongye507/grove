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

    var body: some View {
        TreeArt(
            speciesId: speciesId,
            progress: clamped,
            wilted: wilted,
            size: compact ? .bed : .hero
        )
        .clipped()
        .animation(.easeInOut(duration: 0.55), value: clamped)
        .animation(.easeInOut(duration: 0.45), value: wilted)
        .accessibilityLabel("\(speciesName), \(stage.rawValue)")
    }
}
