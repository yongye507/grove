import SwiftUI

enum TreeStage: String {
    case sprout = "Sprouting"
    case sapling = "Growing"
    case leafy = "Leafing out"
    case mature = "Fully grown"
    case wilted = "Wilted"

    var localizedTitle: String {
        String(localized: String.LocalizationValue(rawValue))
    }

    static func from(progress: Double, wilted: Bool) -> TreeStage {
        if wilted { return .wilted }
        switch min(max(progress, 0), 1) {
        case ..<0.25: return .sprout
        case ..<0.5: return .sapling
        case ..<0.75: return .leafy
        default: return .mature
        }
    }
}

/// Shared vector plant art used on Plant page and Grove week beds.
/// Species differ by silhouette (not only color) so chip-sized beds stay readable.
struct TreeArt: View {
    var speciesId: String
    var progress: Double
    var wilted: Bool
    /// `.hero` for Plant page, `.bed` for week plot cells, `.chip` for tiny legends
    var size: ArtSize = .hero

    enum ArtSize {
        case hero, bed, chip
    }

    private var clamped: Double { min(max(progress, 0), 1) }
    private var stage: TreeStage { .from(progress: clamped, wilted: wilted) }
    private var palette: SpeciesPalette { .forSpecies(speciesId, wilted: wilted) }

    var body: some View {
        Canvas { context, canvasSize in
            draw(in: &context, width: canvasSize.width, height: canvasSize.height)
        }
        .accessibilityLabel("\(TreeCatalog.species(id: speciesId)?.localizedName ?? speciesId), \(stage.localizedTitle)")
    }

    private func draw(in context: inout GraphicsContext, width: CGFloat, height: CGFloat) {
        let potH = height * (size == .chip ? 0.26 : 0.22)
        let potW = width * (size == .chip ? 0.64 : 0.46)
        let potOrigin = CGPoint(x: (width - potW) / 2, y: height - potH - height * 0.03)

        var shadow = Path(ellipseIn: CGRect(
            x: width * 0.22,
            y: height - height * 0.06,
            width: width * 0.56,
            height: height * 0.045
        ))
        context.fill(shadow, with: .color(.black.opacity(wilted ? 0.04 : 0.08)))

        var pot = Path()
        let inset = potW * 0.12
        pot.move(to: CGPoint(x: potOrigin.x, y: potOrigin.y + potH * 0.18))
        pot.addLine(to: CGPoint(x: potOrigin.x + potW, y: potOrigin.y + potH * 0.18))
        pot.addLine(to: CGPoint(x: potOrigin.x + potW - inset, y: potOrigin.y + potH))
        pot.addLine(to: CGPoint(x: potOrigin.x + inset, y: potOrigin.y + potH))
        pot.closeSubpath()
        context.fill(
            pot,
            with: .linearGradient(
                Gradient(colors: [palette.potTop, palette.potBottom]),
                startPoint: CGPoint(x: width / 2, y: potOrigin.y),
                endPoint: CGPoint(x: width / 2, y: potOrigin.y + potH)
            )
        )

        let rim = Path(roundedRect: CGRect(
            x: potOrigin.x - potW * 0.04,
            y: potOrigin.y,
            width: potW * 1.08,
            height: potH * 0.18
        ), cornerRadius: potH * 0.08)
        context.fill(rim, with: .color(palette.potRim))

        let soil = Path(ellipseIn: CGRect(
            x: potOrigin.x + potW * 0.12,
            y: potOrigin.y + potH * 0.12,
            width: potW * 0.76,
            height: potH * 0.16
        ))
        context.fill(soil, with: .color(palette.soil))

        let plantBottom = potOrigin.y + potH * 0.18
        // Keep canopy inside the canvas so timers / titles above the view aren't covered.
        let topInset = height * (size == .chip ? 0.04 : 0.10)
        let rawPlantH = height * (0.30 + clamped * 0.28)
        let maxPlantH = min(rawPlantH, max(8, plantBottom - topInset))
        let trunkTop = plantBottom - maxPlantH
        let droopX = wilted ? width * 0.035 : 0
        let trunkBaseX = width / 2

        // Trunk
        var trunk = Path()
        let trunkW = max(2.0, width * (speciesId == "pine" ? 0.045 : 0.035))
        trunk.move(to: CGPoint(x: trunkBaseX - trunkW / 2, y: plantBottom))
        trunk.addLine(to: CGPoint(x: trunkBaseX + droopX - trunkW / 3, y: trunkTop + maxPlantH * 0.22))
        trunk.addLine(to: CGPoint(x: trunkBaseX + droopX + trunkW / 3, y: trunkTop + maxPlantH * 0.22))
        trunk.addLine(to: CGPoint(x: trunkBaseX + trunkW / 2, y: plantBottom))
        trunk.closeSubpath()
        context.fill(trunk, with: .color(palette.trunk))

        let canopyCenter = CGPoint(x: trunkBaseX + droopX, y: trunkTop + maxPlantH * 0.3)
        if stage == .sprout || (clamped < 0.2 && !wilted) {
            drawSprout(in: &context, center: canopyCenter, plantHeight: maxPlantH, width: width)
        } else {
            drawSpeciesCanopy(
                in: &context,
                center: canopyCenter,
                plantHeight: maxPlantH,
                width: width
            )
        }
    }

    private func drawSprout(
        in context: inout GraphicsContext,
        center: CGPoint,
        plantHeight: CGFloat,
        width: CGFloat
    ) {
        for sign: CGFloat in [-1, 1] {
            var leaf = Path()
            let tip = CGPoint(x: center.x + sign * width * 0.1, y: center.y)
            leaf.move(to: CGPoint(x: center.x, y: center.y + plantHeight * 0.08))
            leaf.addQuadCurve(
                to: tip,
                control: CGPoint(x: center.x + sign * width * 0.06, y: center.y - plantHeight * 0.02)
            )
            leaf.addQuadCurve(
                to: CGPoint(x: center.x, y: center.y + plantHeight * 0.08),
                control: CGPoint(x: center.x + sign * width * 0.03, y: center.y + plantHeight * 0.03)
            )
            context.fill(leaf, with: .color(palette.leafMain))
        }
    }

    private func drawSpeciesCanopy(
        in context: inout GraphicsContext,
        center: CGPoint,
        plantHeight: CGFloat,
        width: CGFloat
    ) {
        switch speciesId {
        case "pine":
            drawPine(in: &context, center: center, plantHeight: plantHeight, width: width)
        case "sakura":
            drawSakura(in: &context, center: center, plantHeight: plantHeight, width: width)
        case "maple":
            drawMaple(in: &context, center: center, plantHeight: plantHeight, width: width)
        default:
            drawOak(in: &context, center: center, plantHeight: plantHeight, width: width)
        }
    }

    /// Round leafy cloud — oak default.
    private func drawOak(
        in context: inout GraphicsContext,
        center: CGPoint,
        plantHeight: CGFloat,
        width: CGFloat
    ) {
        let blobs: [(CGFloat, CGFloat, CGFloat)] = {
            switch stage {
            case .sapling:
                return [(0, 0, 0.55), (-0.14, 0.08, 0.38), (0.14, 0.1, 0.36)]
            case .leafy:
                return [(0, 0, 0.7), (-0.18, 0.06, 0.5), (0.18, 0.08, 0.48), (0, -0.12, 0.4)]
            default:
                return [
                    (0, 0, 0.82), (-0.22, 0.05, 0.58), (0.22, 0.06, 0.56),
                    (-0.08, -0.14, 0.48), (0.1, -0.12, 0.46), (0, 0.14, 0.42)
                ]
            }
        }()
        for (i, blob) in blobs.enumerated() {
            let r = plantHeight * blob.2 * (size == .chip ? 0.92 : 1)
            let rect = CGRect(
                x: center.x + width * blob.0 - r / 2,
                y: center.y + plantHeight * blob.1 - r / 2,
                width: r,
                height: r * 0.9
            )
            let color = i == 0 ? palette.leafMain : (i % 2 == 0 ? palette.leafLight : palette.leafDark)
            context.fill(Path(ellipseIn: rect), with: .color(color.opacity(wilted ? 0.8 : 1)))
        }
    }

    /// Layered triangles — pine.
    private func drawPine(
        in context: inout GraphicsContext,
        center: CGPoint,
        plantHeight: CGFloat,
        width: CGFloat
    ) {
        let layers = stage == .sapling ? 2 : (stage == .leafy ? 3 : 4)
        for i in 0..<layers {
            let t = CGFloat(i) / CGFloat(max(layers - 1, 1))
            let topY = center.y - plantHeight * 0.28 + t * plantHeight * 0.42
            let halfW = width * (0.12 + t * 0.22)
            let tipY = topY - plantHeight * 0.16
            var tri = Path()
            tri.move(to: CGPoint(x: center.x, y: tipY))
            tri.addLine(to: CGPoint(x: center.x + halfW, y: topY + plantHeight * 0.08))
            tri.addLine(to: CGPoint(x: center.x - halfW, y: topY + plantHeight * 0.08))
            tri.closeSubpath()
            let color = i % 2 == 0 ? palette.leafMain : palette.leafDark
            context.fill(tri, with: .color(color.opacity(wilted ? 0.8 : 1)))
        }
    }

    /// Soft pink cloud + petal dots — sakura.
    private func drawSakura(
        in context: inout GraphicsContext,
        center: CGPoint,
        plantHeight: CGFloat,
        width: CGFloat
    ) {
        let clouds: [(CGFloat, CGFloat, CGFloat)] = [
            (0, 0, 0.72), (-0.2, 0.06, 0.5), (0.2, 0.08, 0.48), (0, -0.14, 0.44)
        ]
        for (i, blob) in clouds.enumerated() {
            let r = plantHeight * blob.2
            let rect = CGRect(
                x: center.x + width * blob.0 - r / 2,
                y: center.y + plantHeight * blob.1 - r / 2,
                width: r,
                height: r * 0.88
            )
            let color = i == 0 ? palette.leafMain : palette.leafLight
            context.fill(Path(ellipseIn: rect), with: .color(color.opacity(wilted ? 0.75 : 1)))
        }
        // Petal flecks
        let flecks: [(CGFloat, CGFloat)] = [
            (-0.12, -0.06), (0.14, -0.02), (-0.02, 0.1), (0.08, 0.12), (-0.16, 0.08)
        ]
        for fleck in flecks {
            let r = max(2.0, width * 0.045)
            let rect = CGRect(
                x: center.x + width * fleck.0 - r / 2,
                y: center.y + plantHeight * fleck.1 - r / 2,
                width: r,
                height: r
            )
            context.fill(Path(ellipseIn: rect), with: .color(palette.leafDark.opacity(wilted ? 0.55 : 0.9)))
        }
    }

    /// Pointed star / maple leaves — maple.
    private func drawMaple(
        in context: inout GraphicsContext,
        center: CGPoint,
        plantHeight: CGFloat,
        width: CGFloat
    ) {
        let leaves: [(CGFloat, CGFloat, CGFloat, Color)] = [
            (0, -0.02, 0.55, palette.leafMain),
            (-0.2, 0.08, 0.4, palette.leafDark),
            (0.2, 0.1, 0.38, palette.leafLight),
            (0, 0.16, 0.34, palette.leafMain)
        ]
        for leaf in leaves.prefix(stage == .sapling ? 2 : 4) {
            let s = plantHeight * leaf.2
            let c = CGPoint(x: center.x + width * leaf.0, y: center.y + plantHeight * leaf.1)
            context.fill(mapleLeafPath(center: c, size: s), with: .color(leaf.3.opacity(wilted ? 0.8 : 1)))
        }
    }

    private func mapleLeafPath(center: CGPoint, size: CGFloat) -> Path {
        // Simple 5-point maple-ish star.
        var path = Path()
        let tips: [(CGFloat, CGFloat)] = [
            (0, -0.55), (0.22, -0.18), (0.5, -0.12), (0.28, 0.12),
            (0.32, 0.48), (0, 0.28), (-0.32, 0.48), (-0.28, 0.12),
            (-0.5, -0.12), (-0.22, -0.18)
        ]
        for (i, tip) in tips.enumerated() {
            let p = CGPoint(x: center.x + tip.0 * size, y: center.y + tip.1 * size)
            if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        return path
    }
}

private struct SpeciesPalette {
    var leafMain: Color
    var leafLight: Color
    var leafDark: Color
    var trunk: Color
    var potTop: Color
    var potBottom: Color
    var potRim: Color
    var soil: Color

    static func forSpecies(_ id: String, wilted: Bool) -> SpeciesPalette {
        // Wilted keeps a faint species tint so beds stay distinguishable.
        if wilted {
            switch id {
            case "sakura":
                return SpeciesPalette(
                    leafMain: Color(hex: "C4B0B6"),
                    leafLight: Color(hex: "D4C6CB"),
                    leafDark: Color(hex: "A8989E"),
                    trunk: Color(hex: "7A6A58"),
                    potTop: GroveTheme.wiltSoil,
                    potBottom: Color(hex: "7A6B5A"),
                    potRim: Color(hex: "6E6358"),
                    soil: Color(hex: "5C534A")
                )
            case "maple":
                return SpeciesPalette(
                    leafMain: Color(hex: "B8A090"),
                    leafLight: Color(hex: "C8B4A4"),
                    leafDark: Color(hex: "9A8678"),
                    trunk: Color(hex: "7A6A58"),
                    potTop: GroveTheme.wiltSoil,
                    potBottom: Color(hex: "7A6B5A"),
                    potRim: Color(hex: "6E6358"),
                    soil: Color(hex: "5C534A")
                )
            case "pine":
                return SpeciesPalette(
                    leafMain: Color(hex: "9AA898"),
                    leafLight: Color(hex: "B0BAAE"),
                    leafDark: Color(hex: "7E8A7C"),
                    trunk: Color(hex: "7A6A58"),
                    potTop: GroveTheme.wiltSoil,
                    potBottom: Color(hex: "7A6B5A"),
                    potRim: Color(hex: "6E6358"),
                    soil: Color(hex: "5C534A")
                )
            default:
                return SpeciesPalette(
                    leafMain: GroveTheme.wiltLeaf,
                    leafLight: Color(hex: "B8BCAE"),
                    leafDark: Color(hex: "8A8E80"),
                    trunk: Color(hex: "7A6A58"),
                    potTop: GroveTheme.wiltSoil,
                    potBottom: Color(hex: "7A6B5A"),
                    potRim: Color(hex: "6E6358"),
                    soil: Color(hex: "5C534A")
                )
            }
        }
        switch id {
        case "pine":
            return SpeciesPalette(
                leafMain: Color(hex: "2F5D3A"),
                leafLight: Color(hex: "4A7A52"),
                leafDark: Color(hex: "1F3F28"),
                trunk: Color(hex: "5C4033"),
                potTop: GroveTheme.pot,
                potBottom: GroveTheme.potRim,
                potRim: Color(hex: "9A7A55"),
                soil: GroveTheme.soil
            )
        case "sakura":
            return SpeciesPalette(
                leafMain: Color(hex: "E8A0B5"),
                leafLight: Color(hex: "F3C4D0"),
                leafDark: Color(hex: "C97890"),
                trunk: Color(hex: "6B5344"),
                potTop: GroveTheme.pot,
                potBottom: GroveTheme.potRim,
                potRim: Color(hex: "9A7A55"),
                soil: GroveTheme.soil
            )
        case "willow":
            return SpeciesPalette(
                leafMain: Color(hex: "7FA86A"),
                leafLight: Color(hex: "A5C98B"),
                leafDark: Color(hex: "5F8250"),
                trunk: Color(hex: "6B5344"),
                potTop: GroveTheme.pot,
                potBottom: GroveTheme.potRim,
                potRim: Color(hex: "9A7A55"),
                soil: GroveTheme.soil
            )
        case "maple":
            return SpeciesPalette(
                leafMain: Color(hex: "C45C26"),
                leafLight: Color(hex: "E08A4A"),
                leafDark: Color(hex: "8F3B15"),
                trunk: Color(hex: "5C4033"),
                potTop: GroveTheme.pot,
                potBottom: GroveTheme.potRim,
                potRim: Color(hex: "9A7A55"),
                soil: GroveTheme.soil
            )
        case "baobab":
            return SpeciesPalette(
                leafMain: Color(hex: "6B8F3C"),
                leafLight: Color(hex: "8FB35A"),
                leafDark: Color(hex: "4A6A28"),
                trunk: Color(hex: "8B7355"),
                potTop: GroveTheme.pot,
                potBottom: GroveTheme.potRim,
                potRim: Color(hex: "9A7A55"),
                soil: GroveTheme.soil
            )
        default: // oak
            return SpeciesPalette(
                leafMain: GroveTheme.moss,
                leafLight: GroveTheme.leafLight,
                leafDark: GroveTheme.mossDeep,
                trunk: GroveTheme.soil,
                potTop: GroveTheme.pot,
                potBottom: GroveTheme.potRim,
                potRim: Color(hex: "9A7A55"),
                soil: GroveTheme.soil
            )
        }
    }
}
