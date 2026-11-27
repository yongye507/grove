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
    /// 0…1 — citrus fruit pop-in (animated on the outcome card).
    var fruitBloom: Double = 1

    enum ArtSize {
        case hero, bed, chip
    }

    private var clamped: Double { min(max(progress, 0), 1) }
    private var stage: TreeStage { .from(progress: clamped, wilted: wilted) }
    private var palette: SpeciesPalette { .forSpecies(speciesId, wilted: wilted) }
    private var bloom: Double { min(max(fruitBloom, 0), 1) }

    var body: some View {
        TreeArtCanvas(
            speciesId: speciesId,
            progress: clamped,
            wilted: wilted,
            size: size,
            fruitBloom: bloom
        )
        .accessibilityLabel("\(TreeCatalog.species(id: speciesId)?.localizedName ?? speciesId), \(stage.localizedTitle)")
    }
}

/// Animatable wrapper so fruit bloom interpolates inside Canvas.
private struct TreeArtCanvas: View, Animatable {
    var speciesId: String
    var progress: Double
    var wilted: Bool
    var size: TreeArt.ArtSize
    var fruitBloom: Double

    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(progress, fruitBloom) }
        set {
            progress = newValue.first
            fruitBloom = newValue.second
        }
    }

    private var clamped: Double { min(max(progress, 0), 1) }
    private var stage: TreeStage { .from(progress: clamped, wilted: wilted) }
    private var palette: SpeciesPalette { .forSpecies(speciesId, wilted: wilted) }
    private var bloom: Double { min(max(fruitBloom, 0), 1) }

    var body: some View {
        Canvas { context, canvasSize in
            draw(in: &context, width: canvasSize.width, height: canvasSize.height)
        }
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
        // Tiny top margin only — large insets left empty space while clip still cut ear/leaf tips.
        // Timer / titles sit outside this view now, so the canopy may use almost the full height.
        let topInset = height * (size == .chip ? 0.02 : 0.025)
        let rawPlantH = height * (0.30 + clamped * 0.28)
        let maxPlantH = min(rawPlantH, max(8, plantBottom - topInset))
        let trunkTop = plantBottom - maxPlantH
        let droopX = wilted ? width * 0.035 : 0
        let trunkBaseX = width / 2

        // Flowering shrubs draw their own stem — skip the woody trunk stub.
        let isFlowerShrub = ["peony", "rose", "willow"].contains(speciesId)
        if !isFlowerShrub {
            var trunk = Path()
            let trunkScale: CGFloat = {
                switch speciesId {
                case "pine": return 0.045
                case "baobab": return 0.11
                default: return 0.035
                }
            }()
            let trunkW = max(2.0, width * trunkScale)
            // Pine trunk runs higher so early tiers don't float above a short stump.
            let trunkEndY: CGFloat = {
                switch speciesId {
                case "pine": return trunkTop + maxPlantH * 0.10
                default: return trunkTop + maxPlantH * 0.22
                }
            }()
            trunk.move(to: CGPoint(x: trunkBaseX - trunkW / 2, y: plantBottom))
            trunk.addLine(to: CGPoint(x: trunkBaseX + droopX - trunkW / 3, y: trunkEndY))
            trunk.addLine(to: CGPoint(x: trunkBaseX + droopX + trunkW / 3, y: trunkEndY))
            trunk.addLine(to: CGPoint(x: trunkBaseX + trunkW / 2, y: plantBottom))
            trunk.closeSubpath()
            context.fill(trunk, with: .color(palette.trunk))
        }

        // Flower shrubs sit a bit lower so blooms aren't clipped at the top.
        let canopyCenter = CGPoint(
            x: trunkBaseX + droopX,
            y: trunkTop + maxPlantH * (isFlowerShrub ? 0.42 : 0.34)
        )
        // Clip to nearly the full canvas — only keep a hairline edge so rounded corners
        // don't shave fox ears / owl tufts / peony petals (those draw above trunkTop).
        let clipRect = CGRect(
            x: width * 0.02,
            y: height * 0.005,
            width: width * 0.96,
            height: max(4, plantBottom - height * 0.005 + maxPlantH * 0.02)
        )
        context.clip(to: Path(roundedRect: clipRect, cornerRadius: width * 0.02))

        if stage == .sprout || (clamped < 0.2 && !wilted) {
            // Leaf joint sits clearly above the pot rim; stem roots into the soil.
            let sproutLift = isFlowerShrub ? 0.30 : 0.22
            let sproutCenter = CGPoint(
                x: trunkBaseX + droopX,
                y: plantBottom - maxPlantH * sproutLift
            )
            drawSprout(
                in: &context,
                center: sproutCenter,
                soilY: plantBottom,
                plantHeight: maxPlantH,
                width: width
            )
        } else {
            drawSpeciesCanopy(
                in: &context,
                center: canopyCenter,
                plantHeight: maxPlantH,
                width: width,
                stemBaseY: plantBottom
            )
            if shouldDrawFruit {
                drawFruit(
                    in: &context,
                    center: canopyCenter,
                    plantHeight: maxPlantH,
                    width: width
                )
            }
        }
    }

    private var shouldDrawFruit: Bool {
        guard !wilted, stage == .mature, bloom > 0.02 else { return false }
        return TreeCatalog.species(id: speciesId)?.bearsFruit == true
    }

    private func drawSprout(
        in context: inout GraphicsContext,
        center: CGPoint,
        soilY: CGFloat,
        plantHeight: CGFloat,
        width: CGFloat
    ) {
        // Short stem from soil up to the cotyledon joint — keeps leaves off the pot rim.
        let stemW = max(1.4, width * 0.014)
        var stem = Path()
        stem.move(to: CGPoint(x: center.x - stemW / 2, y: soilY))
        stem.addLine(to: CGPoint(x: center.x - stemW / 3, y: center.y))
        stem.addLine(to: CGPoint(x: center.x + stemW / 3, y: center.y))
        stem.addLine(to: CGPoint(x: center.x + stemW / 2, y: soilY))
        stem.closeSubpath()
        context.fill(stem, with: .color(palette.trunk.opacity(0.85)))

        // Two buds open upward / outward from the joint (never down into the pot).
        for sign: CGFloat in [-1, 1] {
            var leaf = Path()
            let base = CGPoint(x: center.x, y: center.y)
            let tip = CGPoint(
                x: center.x + sign * width * 0.11,
                y: center.y - plantHeight * 0.16
            )
            leaf.move(to: base)
            leaf.addQuadCurve(
                to: tip,
                control: CGPoint(
                    x: center.x + sign * width * 0.09,
                    y: center.y - plantHeight * 0.02
                )
            )
            leaf.addQuadCurve(
                to: base,
                control: CGPoint(
                    x: center.x + sign * width * 0.03,
                    y: center.y - plantHeight * 0.10
                )
            )
            context.fill(leaf, with: .color(palette.leafMain))
        }
    }

    private func drawSpeciesCanopy(
        in context: inout GraphicsContext,
        center: CGPoint,
        plantHeight: CGFloat,
        width: CGFloat,
        stemBaseY: CGFloat
    ) {
        switch speciesId {
        case "pine":
            drawPine(in: &context, center: center, plantHeight: plantHeight, width: width)
        case "sakura":
            drawSakura(in: &context, center: center, plantHeight: plantHeight, width: width)
        case "maple":
            drawMaple(in: &context, center: center, plantHeight: plantHeight, width: width)
        case "peony", "rose", "willow":
            drawPeony(
                in: &context,
                center: center,
                plantHeight: plantHeight,
                width: width,
                stemBaseY: stemBaseY
            )
        case "baobab":
            drawBaobab(in: &context, center: center, plantHeight: plantHeight, width: width)
        case "ginkgo":
            drawGinkgo(in: &context, center: center, plantHeight: plantHeight, width: width)
        case "orange", "lemon":
            drawCitrus(in: &context, center: center, plantHeight: plantHeight, width: width)
        case "owl":
            drawOwl(in: &context, center: center, plantHeight: plantHeight, width: width)
        case "fox":
            drawFox(in: &context, center: center, plantHeight: plantHeight, width: width)
        default:
            drawOak(in: &context, center: center, plantHeight: plantHeight, width: width)
        }
    }

    /// Offsets are fractions of `plantHeight` (not canvas width) so foliage stays in-bounds.
    private func leafPoint(center: CGPoint, plantHeight: CGFloat, dx: CGFloat, dy: CGFloat) -> CGPoint {
        CGPoint(x: center.x + plantHeight * dx, y: center.y + plantHeight * dy)
    }

    /// Round leafy cloud — oak.
    private func drawOak(
        in context: inout GraphicsContext,
        center: CGPoint,
        plantHeight: CGFloat,
        width: CGFloat
    ) {
        let blobs: [(CGFloat, CGFloat, CGFloat)] = {
            switch stage {
            case .sapling:
                return [(0, 0.02, 0.42), (-0.16, 0.1, 0.3), (0.16, 0.12, 0.28)]
            case .leafy:
                return [(0, 0, 0.52), (-0.2, 0.08, 0.36), (0.2, 0.1, 0.34), (0, -0.12, 0.3)]
            default:
                return [
                    (0, 0, 0.58), (-0.22, 0.06, 0.4), (0.22, 0.08, 0.38),
                    (-0.08, -0.14, 0.34), (0.1, -0.12, 0.32), (0, 0.14, 0.3)
                ]
            }
        }()
        let shrink = size == .chip ? 0.9 : 1
        for (i, blob) in blobs.enumerated() {
            let r = plantHeight * blob.2 * shrink
            let c = leafPoint(center: center, plantHeight: plantHeight, dx: blob.0, dy: blob.1)
            let rect = CGRect(x: c.x - r / 2, y: c.y - r / 2, width: r, height: r * 0.9)
            let color = i == 0 ? palette.leafMain : (i % 2 == 0 ? palette.leafLight : palette.leafDark)
            context.fill(Path(ellipseIn: rect), with: .color(color.opacity(wilted ? 0.8 : 1)))
        }
    }

    /// Layered triangles — pine / Christmas-tree silhouette.
    /// Tiers stack continuously from tip down onto the trunk (no floating top).
    private func drawPine(
        in context: inout GraphicsContext,
        center: CGPoint,
        plantHeight: CGFloat,
        width: CGFloat
    ) {
        let layers = stage == .sapling ? 2 : (stage == .leafy ? 3 : 4)
        let tipY = center.y - plantHeight * 0.30
        // Bottom tier sits on / overlaps the trunk tip.
        let baseY = center.y + plantHeight * 0.20
        for i in 0..<layers {
            let t0 = CGFloat(i) / CGFloat(layers)
            let t1 = CGFloat(i + 1) / CGFloat(layers)
            let layerTipY = tipY + (baseY - tipY) * t0
            // Overlap into the next tier so layers read as one tree.
            let layerBaseY = tipY + (baseY - tipY) * t1 + plantHeight * 0.03
            let halfW = plantHeight * (0.14 + t1 * 0.26)
            var tri = Path()
            tri.move(to: CGPoint(x: center.x, y: layerTipY))
            tri.addLine(to: CGPoint(x: center.x + halfW, y: layerBaseY))
            tri.addLine(to: CGPoint(x: center.x - halfW, y: layerBaseY))
            tri.closeSubpath()
            let color = i % 2 == 0 ? palette.leafMain : palette.leafDark
            context.fill(tri, with: .color(color.opacity(wilted ? 0.8 : 1)))
        }
    }

    /// Soft pink cloud + petal flecks — sakura.
    private func drawSakura(
        in context: inout GraphicsContext,
        center: CGPoint,
        plantHeight: CGFloat,
        width: CGFloat
    ) {
        let clouds: [(CGFloat, CGFloat, CGFloat)] = [
            (0, 0, 0.5), (-0.2, 0.08, 0.34), (0.2, 0.1, 0.32), (0, -0.12, 0.3)
        ]
        for (i, blob) in clouds.enumerated() {
            let r = plantHeight * blob.2
            let c = leafPoint(center: center, plantHeight: plantHeight, dx: blob.0, dy: blob.1)
            let rect = CGRect(x: c.x - r / 2, y: c.y - r / 2, width: r, height: r * 0.88)
            let color = i == 0 ? palette.leafMain : palette.leafLight
            context.fill(Path(ellipseIn: rect), with: .color(color.opacity(wilted ? 0.75 : 1)))
        }
        let flecks: [(CGFloat, CGFloat)] = [
            (-0.12, -0.04), (0.14, 0.0), (-0.02, 0.12), (0.08, 0.1), (-0.16, 0.08)
        ]
        for fleck in flecks {
            let r = max(1.8, plantHeight * 0.055)
            let c = leafPoint(center: center, plantHeight: plantHeight, dx: fleck.0, dy: fleck.1)
            let rect = CGRect(x: c.x - r / 2, y: c.y - r / 2, width: r, height: r)
            context.fill(Path(ellipseIn: rect), with: .color(palette.leafDark.opacity(wilted ? 0.55 : 0.9)))
        }
    }

    /// Lobed maple leaves clustered into a crown.
    private func drawMaple(
        in context: inout GraphicsContext,
        center: CGPoint,
        plantHeight: CGFloat,
        width: CGFloat
    ) {
        let leaves: [(CGFloat, CGFloat, CGFloat, Color)] = [
            (0, -0.02, 0.42, palette.leafMain),
            (-0.2, 0.1, 0.3, palette.leafDark),
            (0.2, 0.12, 0.28, palette.leafLight),
            (0, 0.16, 0.26, palette.leafMain)
        ]
        for leaf in leaves.prefix(stage == .sapling ? 2 : 4) {
            let s = plantHeight * leaf.2
            let c = leafPoint(center: center, plantHeight: plantHeight, dx: leaf.0, dy: leaf.1)
            context.fill(mapleLeafPath(center: c, size: s), with: .color(leaf.3.opacity(wilted ? 0.8 : 1)))
        }
    }

    private func mapleLeafPath(center: CGPoint, size: CGFloat) -> Path {
        var path = Path()
        // Soft 5-lobe maple: tip, side lobes, lower lobes — not a sharp star.
        let tips: [(CGFloat, CGFloat)] = [
            (0, -0.52),
            (0.16, -0.28), (0.42, -0.18), (0.22, 0.02),
            (0.36, 0.28), (0.12, 0.22),
            (0, 0.38),
            (-0.12, 0.22), (-0.36, 0.28), (-0.22, 0.02),
            (-0.42, -0.18), (-0.16, -0.28)
        ]
        for (i, tip) in tips.enumerated() {
            let p = CGPoint(x: center.x + tip.0 * size, y: center.y + tip.1 * size)
            if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        return path
    }

    /// Peony bush — stem rooted in pot soil; side shoots fork mid-stem and always end in a bloom.
    private func drawPeony(
        in context: inout GraphicsContext,
        center: CGPoint,
        plantHeight: CGFloat,
        width: CGFloat,
        stemBaseY: CGFloat
    ) {
        // Anchor in the soil line of the pot (not floating under the canopy center).
        let root = CGPoint(x: center.x, y: stemBaseY)
        let mainTip = CGPoint(x: center.x, y: stemBaseY - plantHeight * 0.72)
        let mainWidth = max(2.0, plantHeight * 0.045)

        // Main stem as a tapered filled path (consistent thickness, no trunk clash).
        drawTaperedStem(
            in: &context,
            from: root,
            to: mainTip,
            baseWidth: mainWidth,
            tipWidth: mainWidth * 0.55
        )

        // Leaves along main stem.
        let leafCount = stage == .sapling ? 2 : 4
        for li in 0..<leafCount {
            let along = 0.25 + CGFloat(li) * 0.14
            let joint = CGPoint(
                x: root.x + (mainTip.x - root.x) * along,
                y: root.y + (mainTip.y - root.y) * along
            )
            drawPeonyLeaf(
                in: &context,
                from: joint,
                sign: li.isMultiple(of: 2) ? -1 : 1,
                size: plantHeight * 0.14
            )
        }

        // Main bloom / bud at tip.
        let mainOpen: CGFloat = {
            switch stage {
            case .sapling: return 0.2
            case .leafy: return 0.65
            default: return 1.0
            }
        }()
        drawPeonyBloom(
            in: &context,
            center: mainTip,
            size: plantHeight * (0.18 + mainOpen * 0.1),
            openness: mainOpen
        )

        // Side shoots only after sapling — fork from mid-stem, thinner, each with its own bloom.
        if stage != .sapling {
            let forks: [(along: CGFloat, lean: CGFloat, open: CGFloat)] = {
                switch stage {
                case .leafy:
                    return [(0.55, -0.2, 0.3)]
                default:
                    return [(0.48, -0.22, 0.75), (0.58, 0.2, 0.55)]
                }
            }()
            for fork in forks {
                let joint = CGPoint(
                    x: root.x + (mainTip.x - root.x) * fork.along,
                    y: root.y + (mainTip.y - root.y) * fork.along
                )
                let tip = CGPoint(
                    x: joint.x + plantHeight * fork.lean,
                    y: joint.y - plantHeight * 0.16
                )
                drawTaperedStem(
                    in: &context,
                    from: joint,
                    to: tip,
                    baseWidth: mainWidth * 0.55,
                    tipWidth: mainWidth * 0.35
                )
                drawPeonyLeaf(
                    in: &context,
                    from: CGPoint(
                        x: joint.x + (tip.x - joint.x) * 0.45,
                        y: joint.y + (tip.y - joint.y) * 0.45
                    ),
                    sign: fork.lean >= 0 ? 1 : -1,
                    size: plantHeight * 0.11
                )
                drawPeonyBloom(
                    in: &context,
                    center: tip,
                    size: plantHeight * (0.12 + fork.open * 0.08),
                    openness: fork.open
                )
            }
        }
    }

    private func drawTaperedStem(
        in context: inout GraphicsContext,
        from: CGPoint,
        to: CGPoint,
        baseWidth: CGFloat,
        tipWidth: CGFloat
    ) {
        let dx = to.x - from.x
        let dy = to.y - from.y
        let len = max(0.001, sqrt(dx * dx + dy * dy))
        let nx = -dy / len
        let ny = dx / len
        var path = Path()
        path.move(to: CGPoint(x: from.x + nx * baseWidth / 2, y: from.y + ny * baseWidth / 2))
        path.addLine(to: CGPoint(x: to.x + nx * tipWidth / 2, y: to.y + ny * tipWidth / 2))
        path.addLine(to: CGPoint(x: to.x - nx * tipWidth / 2, y: to.y - ny * tipWidth / 2))
        path.addLine(to: CGPoint(x: from.x - nx * baseWidth / 2, y: from.y - ny * baseWidth / 2))
        path.closeSubpath()
        context.fill(path, with: .color(palette.trunk.opacity(wilted ? 0.7 : 1)))
    }

    private func drawPeonyLeaf(
        in context: inout GraphicsContext,
        from joint: CGPoint,
        sign: CGFloat,
        size: CGFloat
    ) {
        // Peony leaf: elongated, pointed, slightly lobed (tutorial: feather-like).
        var leaf = Path()
        let tip = CGPoint(x: joint.x + sign * size * 1.15, y: joint.y - size * 0.2)
        leaf.move(to: joint)
        leaf.addQuadCurve(
            to: tip,
            control: CGPoint(x: joint.x + sign * size * 0.35, y: joint.y - size * 0.55)
        )
        // Slight lobe on the lower edge
        leaf.addQuadCurve(
            to: CGPoint(x: joint.x + sign * size * 0.55, y: joint.y + size * 0.15),
            control: CGPoint(x: joint.x + sign * size * 0.95, y: joint.y + size * 0.25)
        )
        leaf.addQuadCurve(
            to: joint,
            control: CGPoint(x: joint.x + sign * size * 0.25, y: joint.y + size * 0.2)
        )
        context.fill(leaf, with: .color(palette.leafMain.opacity(wilted ? 0.75 : 1)))
        var vein = Path()
        vein.move(to: joint)
        vein.addLine(to: tip)
        context.stroke(
            vein,
            with: .color(palette.leafDark.opacity(0.3)),
            style: StrokeStyle(lineWidth: max(0.7, size * 0.05), lineCap: .round)
        )
    }

    /// Peony bloom from drawing refs: center → tight inner petals → larger wavy outer petals.
    /// (Not a ring of identical ellipses.)
    private func drawPeonyBloom(
        in context: inout GraphicsContext,
        center: CGPoint,
        size: CGFloat,
        openness: CGFloat
    ) {
        let open = min(max(openness, 0), 1)
        let fade = wilted ? 0.65 : 1.0

        if open < 0.35 {
            // Cupped bud: a few overlapping inner petals still closed.
            for i in 0..<4 {
                let a = CGFloat(i) * (.pi / 2) - .pi / 4
                context.fill(
                    peonyPetalPath(
                        center: center,
                        angle: a,
                        inner: size * 0.05,
                        outer: size * 0.48,
                        flare: 0.55
                    ),
                    with: .color(palette.fruit.opacity(0.85 * fade))
                )
            }
            for sign: CGFloat in [-1, 1] {
                var sepal = Path()
                sepal.move(to: CGPoint(x: center.x, y: center.y + size * 0.2))
                sepal.addLine(to: CGPoint(x: center.x + sign * size * 0.3, y: center.y + size * 0.02))
                sepal.addLine(to: CGPoint(x: center.x + sign * size * 0.06, y: center.y + size * 0.28))
                sepal.closeSubpath()
                context.fill(sepal, with: .color(palette.leafMain.opacity(0.9)))
            }
            return
        }

        // Outer layer first (behind), then mid, then inner — full peony silhouette.
        let layers: [(count: Int, inner: CGFloat, outer: CGFloat, flare: CGFloat, spin: CGFloat, color: Color)] = [
            (
                open < 0.7 ? 6 : 8,
                size * 0.12,
                size * (0.55 + open * 0.35),
                0.85,
                0.0,
                palette.fruit.opacity(0.88 * fade)
            ),
            (
                6,
                size * 0.08,
                size * (0.4 + open * 0.2),
                0.7,
                0.22,
                palette.leafLight.opacity(0.92 * fade)
            ),
            (
                5,
                size * 0.04,
                size * (0.28 + open * 0.08),
                0.55,
                0.4,
                palette.fruit.opacity(0.95 * fade)
            )
        ]

        for layer in layers {
            for i in 0..<layer.count {
                // Uneven spacing / size so it isn't a perfect daisy ring.
                let jitter = CGFloat((i % 3) - 1) * 0.08
                let a = CGFloat(i) * (.pi * 2 / CGFloat(layer.count)) + layer.spin + jitter
                let outerJ = layer.outer * (1.0 + CGFloat((i % 2) * 2 - 1) * 0.06)
                context.fill(
                    peonyPetalPath(
                        center: center,
                        angle: a,
                        inner: layer.inner,
                        outer: outerJ,
                        flare: layer.flare
                    ),
                    with: .color(layer.color)
                )
            }
        }

        // Anthers — small rice-like ovals at the heart (classic peony tutorial cue).
        let antherR = max(1.2, size * 0.045)
        for i in 0..<6 {
            let a = CGFloat(i) * (.pi * 2 / 6)
            let p = CGPoint(
                x: center.x + cos(a) * size * 0.1,
                y: center.y + sin(a) * size * 0.08
            )
            context.fill(
                Path(ellipseIn: CGRect(
                    x: p.x - antherR * 0.6,
                    y: p.y - antherR,
                    width: antherR * 1.2,
                    height: antherR * 2.0
                )),
                with: .color(Color(hex: "F0D060").opacity(wilted ? 0.45 : 0.95))
            )
        }
    }

    /// One peony petal: grows from near-center outward with a soft wavy tip.
    private func peonyPetalPath(
        center: CGPoint,
        angle: CGFloat,
        inner: CGFloat,
        outer: CGFloat,
        flare: CGFloat
    ) -> Path {
        var path = Path()
        let base = CGPoint(
            x: center.x + cos(angle) * inner,
            y: center.y + sin(angle) * inner
        )
        let tip = CGPoint(
            x: center.x + cos(angle) * outer,
            y: center.y + sin(angle) * outer
        )
        let mid = (inner + outer) * 0.55
        let left = CGPoint(
            x: center.x + cos(angle - flare * 0.55) * mid,
            y: center.y + sin(angle - flare * 0.55) * mid
        )
        let right = CGPoint(
            x: center.x + cos(angle + flare * 0.55) * mid,
            y: center.y + sin(angle + flare * 0.55) * mid
        )
        // Slight notch on the outer edge (wavy peony petal tip).
        let tipLeft = CGPoint(
            x: center.x + cos(angle - 0.18) * outer * 0.92,
            y: center.y + sin(angle - 0.18) * outer * 0.92
        )
        let tipRight = CGPoint(
            x: center.x + cos(angle + 0.18) * outer * 0.92,
            y: center.y + sin(angle + 0.18) * outer * 0.92
        )

        path.move(to: base)
        path.addQuadCurve(to: tipLeft, control: left)
        path.addQuadCurve(to: tip, control: CGPoint(
            x: center.x + cos(angle) * outer * 1.02,
            y: center.y + sin(angle) * outer * 1.02
        ))
        path.addQuadCurve(to: tipRight, control: CGPoint(
            x: center.x + cos(angle + 0.05) * outer * 1.0,
            y: center.y + sin(angle + 0.05) * outer * 1.0
        ))
        path.addQuadCurve(to: base, control: right)
        path.closeSubpath()
        return path
    }

    /// Umbrella tufts on a fat trunk — baobab.
    private func drawBaobab(
        in context: inout GraphicsContext,
        center: CGPoint,
        plantHeight: CGFloat,
        width: CGFloat
    ) {
        let blobs: [(CGFloat, CGFloat, CGFloat)] = [
            (0, -0.1, 0.36), (-0.18, 0.0, 0.26), (0.18, -0.02, 0.24)
        ]
        for (i, blob) in blobs.prefix(stage == .sapling ? 1 : 3).enumerated() {
            let r = plantHeight * blob.2
            let c = leafPoint(center: center, plantHeight: plantHeight, dx: blob.0, dy: blob.1)
            let rect = CGRect(x: c.x - r / 2, y: c.y - r / 2, width: r, height: r * 0.7)
            let color = i == 0 ? palette.leafMain : palette.leafLight
            context.fill(Path(ellipseIn: rect), with: .color(color.opacity(wilted ? 0.8 : 1)))
        }
    }

    /// Classic bilobed fan leaves — ginkgo (柄在下、扇缘在上).
    private func drawGinkgo(
        in context: inout GraphicsContext,
        center: CGPoint,
        plantHeight: CGFloat,
        width: CGFloat
    ) {
        // Each tuple: (stem dx, stem dy, size, lean, color)
        // Stem sits lower; fan opens upward so it reads as a real 扇形叶.
        let fans: [(CGFloat, CGFloat, CGFloat, CGFloat, Color)] = [
            (0.00, 0.10, 0.40, 0.00, palette.leafMain),
            (-0.16, 0.14, 0.32, -0.12, palette.leafLight),
            (0.16, 0.15, 0.31, 0.12, palette.leafDark),
            (-0.06, 0.20, 0.26, -0.05, palette.leafMain),
            (0.07, 0.19, 0.25, 0.06, palette.leafLight)
        ]
        let count = stage == .sapling ? 2 : (stage == .leafy ? 3 : 5)
        for fan in fans.prefix(count) {
            let s = plantHeight * fan.2 * (size == .chip ? 0.9 : 1)
            let stem = leafPoint(center: center, plantHeight: plantHeight, dx: fan.0, dy: fan.1)
            context.fill(
                ginkgoLeafPath(stem: stem, size: s, lean: fan.3),
                with: .color(fan.4.opacity(wilted ? 0.8 : 1))
            )
            if size != .chip {
                drawGinkgoVeins(in: &context, stem: stem, size: s, lean: fan.3)
            }
        }
    }

    /// Fan leaf: narrow petiole at `stem`, widest scalloped rim at the top, cleft in the middle.
    private func ginkgoLeafPath(stem: CGPoint, size: CGFloat, lean: CGFloat) -> Path {
        var path = Path()
        let midX = stem.x + lean * size * 0.1
        let halfW = size * 0.52
        let h = size * 0.82

        // Petiole (narrow bottom)
        path.move(to: stem)

        // Left flank → left rim (widest part is high on the leaf)
        path.addQuadCurve(
            to: CGPoint(x: midX - halfW, y: stem.y - h * 0.42),
            control: CGPoint(x: midX - halfW * 0.22, y: stem.y - h * 0.08)
        )
        // Left outer arc up to left lobe tip
        path.addQuadCurve(
            to: CGPoint(x: midX - halfW * 0.28, y: stem.y - h * 0.88),
            control: CGPoint(x: midX - halfW * 1.02, y: stem.y - h * 0.72)
        )
        // Deep center cleft (signature ginkgo notch)
        path.addQuadCurve(
            to: CGPoint(x: midX, y: stem.y - h * 0.52),
            control: CGPoint(x: midX - halfW * 0.1, y: stem.y - h * 0.7)
        )
        // Up to right lobe tip
        path.addQuadCurve(
            to: CGPoint(x: midX + halfW * 0.28, y: stem.y - h * 0.88),
            control: CGPoint(x: midX + halfW * 0.1, y: stem.y - h * 0.7)
        )
        // Right outer arc down to right rim
        path.addQuadCurve(
            to: CGPoint(x: midX + halfW, y: stem.y - h * 0.42),
            control: CGPoint(x: midX + halfW * 1.02, y: stem.y - h * 0.72)
        )
        // Right flank → petiole
        path.addQuadCurve(
            to: stem,
            control: CGPoint(x: midX + halfW * 0.22, y: stem.y - h * 0.08)
        )
        path.closeSubpath()
        return path
    }

    private func drawGinkgoVeins(
        in context: inout GraphicsContext,
        stem: CGPoint,
        size: CGFloat,
        lean: CGFloat
    ) {
        let midX = stem.x + lean * size * 0.1
        let h = size * 0.82
        let angles: [CGFloat] = [-0.55, -0.28, 0, 0.28, 0.55]
        for (i, a) in angles.enumerated() {
            var vein = Path()
            vein.move(to: CGPoint(x: stem.x, y: stem.y - size * 0.04))
            let end = CGPoint(
                x: midX + size * 0.42 * a,
                y: stem.y - h * (i == 2 ? 0.48 : 0.72)
            )
            vein.addLine(to: end)
            context.stroke(
                vein,
                with: .color(palette.leafDark.opacity(0.28)),
                style: StrokeStyle(lineWidth: max(0.6, size * 0.03), lineCap: .round)
            )
        }
    }

    /// Dense round citrus ball — orange / lemon.
    private func drawCitrus(
        in context: inout GraphicsContext,
        center: CGPoint,
        plantHeight: CGFloat,
        width: CGFloat
    ) {
        let blobs: [(CGFloat, CGFloat, CGFloat)] = {
            switch stage {
            case .sapling:
                return [(0, 0.02, 0.44), (-0.14, 0.1, 0.28), (0.14, 0.12, 0.26)]
            case .leafy:
                return [(0, 0, 0.52), (-0.18, 0.08, 0.34), (0.18, 0.1, 0.32), (0, -0.12, 0.28)]
            default:
                return [
                    (0, 0, 0.56), (-0.2, 0.06, 0.38), (0.2, 0.08, 0.36),
                    (-0.06, -0.14, 0.3), (0.08, -0.12, 0.28)
                ]
            }
        }()
        let shrink = size == .chip ? 0.9 : 1
        for (i, blob) in blobs.enumerated() {
            let r = plantHeight * blob.2 * shrink
            let c = leafPoint(center: center, plantHeight: plantHeight, dx: blob.0, dy: blob.1)
            let rect = CGRect(x: c.x - r / 2, y: c.y - r / 2, width: r, height: r * 0.92)
            let color = i == 0 ? palette.leafMain : (i % 2 == 0 ? palette.leafLight : palette.leafDark)
            context.fill(Path(ellipseIn: rect), with: .color(color.opacity(wilted ? 0.8 : 1)))
        }
    }

    /// Leafy nest behind owl / fox — denser as the tree grows so the trunk isn't bare.
    private func drawAnimalCanopyFoliage(
        in context: inout GraphicsContext,
        center: CGPoint,
        plantHeight: CGFloat
    ) {
        let fill: CGFloat = {
            switch stage {
            case .sprout: return 0.28
            case .sapling: return 0.52
            case .leafy: return 0.82
            case .mature, .wilted: return 1.0
            }
        }()
        let o = wilted ? 0.72 : 1.0
        let greenMain = Color(hex: wilted ? "8A9078" : "3F7A3A").opacity(o)
        let greenLight = Color(hex: wilted ? "A8AE96" : "6AAA58").opacity(o)
        let greenDark = Color(hex: wilted ? "6A705A" : "2A5A28").opacity(o)

        // Soft leaf clouds — animal sits in a growing canopy.
        let clouds: [(CGFloat, CGFloat, CGFloat, Color)] = [
            (0.00, 0.08, 0.78, greenMain),
            (-0.30, 0.00, 0.52, greenDark),
            (0.30, -0.02, 0.52, greenLight),
            (0.00, -0.26, 0.46, greenMain),
            (-0.40, 0.20, 0.40, greenLight),
            (0.40, 0.18, 0.40, greenDark),
            (0.00, 0.32, 0.44, greenMain),
            (-0.18, -0.38, 0.30, greenDark),
            (0.18, -0.36, 0.30, greenLight)
        ]
        let cloudCount = max(3, Int(ceil(Double(clouds.count) * Double(fill))))
        for cloud in clouds.prefix(cloudCount) {
            let r = plantHeight * cloud.2 * (0.72 + 0.28 * fill)
            let c = leafPoint(center: center, plantHeight: plantHeight, dx: cloud.0, dy: cloud.1)
            context.fill(
                Path(ellipseIn: CGRect(x: c.x - r * 0.55, y: c.y - r * 0.45, width: r * 1.1, height: r * 0.9)),
                with: .color(cloud.3)
            )
        }

        // Pointed leaves around the rim so it reads as foliage, not just blobs.
        let tips: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
            (-0.52, -0.08, 0.20, -1.0),
            (0.52, -0.10, 0.20, 1.0),
            (-0.44, 0.26, 0.17, -0.8),
            (0.44, 0.28, 0.17, 0.8),
            (-0.26, -0.42, 0.15, -0.4),
            (0.26, -0.44, 0.15, 0.4),
            (-0.56, 0.10, 0.14, -1.1),
            (0.56, 0.08, 0.14, 1.1)
        ]
        let tipCount = max(2, Int(ceil(Double(tips.count) * Double(fill))))
        for (i, tip) in tips.prefix(tipCount).enumerated() {
            let base = leafPoint(center: center, plantHeight: plantHeight, dx: tip.0 * 0.55, dy: tip.1 * 0.55)
            let end = leafPoint(center: center, plantHeight: plantHeight, dx: tip.0, dy: tip.1)
            let side = plantHeight * tip.2 * 0.35
            var leaf = Path()
            leaf.move(to: base)
            leaf.addQuadCurve(
                to: end,
                control: CGPoint(x: (base.x + end.x) / 2 + tip.3 * side, y: (base.y + end.y) / 2 - side * 0.4)
            )
            leaf.addQuadCurve(
                to: base,
                control: CGPoint(x: (base.x + end.x) / 2 - tip.3 * side * 0.35, y: (base.y + end.y) / 2 + side * 0.25)
            )
            leaf.closeSubpath()
            let color = i % 2 == 0 ? greenLight : greenDark
            context.fill(leaf, with: .color(color))
        }
    }

    /// Owl in a leafy nest — round body, facial discs, big eyes, ear tufts.
    private func drawOwl(
        in context: inout GraphicsContext,
        center: CGPoint,
        plantHeight: CGFloat,
        width: CGFloat
    ) {
        drawAnimalCanopyFoliage(in: &context, center: center, plantHeight: plantHeight)

        let s = plantHeight * (stage == .sapling ? 0.30 : 0.38)
        let o = wilted ? 0.78 : 1.0
        let fur = palette.leafMain.opacity(o)
        let furDeep = palette.leafDark.opacity(o)
        let cream = palette.leafLight.opacity(wilted ? 0.55 : 0.95)
        let ink = palette.trunk.opacity(wilted ? 0.75 : 0.92)
        let beakColor = palette.fruit.opacity(wilted ? 0.65 : 1)

        // Body — plump oval sitting in the leaves.
        context.fill(
            Path(ellipseIn: CGRect(
                x: center.x - s * 0.48,
                y: center.y - s * 0.08,
                width: s * 0.96,
                height: s * 1.05
            )),
            with: .color(fur)
        )
        // Wing folds
        for sign: CGFloat in [-1, 1] {
            context.fill(
                Path(ellipseIn: CGRect(
                    x: center.x + sign * s * 0.22 - s * 0.16,
                    y: center.y + s * 0.12,
                    width: s * 0.32,
                    height: s * 0.62
                )),
                with: .color(furDeep.opacity(0.55))
            )
        }
        // Belly
        context.fill(
            Path(ellipseIn: CGRect(
                x: center.x - s * 0.28,
                y: center.y + s * 0.18,
                width: s * 0.56,
                height: s * 0.58
            )),
            with: .color(cream.opacity(0.85))
        )

        // Head
        context.fill(
            Path(ellipseIn: CGRect(
                x: center.x - s * 0.50,
                y: center.y - s * 0.52,
                width: s * 1.0,
                height: s * 0.88
            )),
            with: .color(fur)
        )

        // Ear tufts
        for sign: CGFloat in [-1, 1] {
            var ear = Path()
            ear.move(to: CGPoint(x: center.x + sign * s * 0.16, y: center.y - s * 0.32))
            ear.addQuadCurve(
                to: CGPoint(x: center.x + sign * s * 0.34, y: center.y - s * 0.78),
                control: CGPoint(x: center.x + sign * s * 0.12, y: center.y - s * 0.58)
            )
            ear.addQuadCurve(
                to: CGPoint(x: center.x + sign * s * 0.46, y: center.y - s * 0.28),
                control: CGPoint(x: center.x + sign * s * 0.48, y: center.y - s * 0.52)
            )
            ear.closeSubpath()
            context.fill(ear, with: .color(furDeep))
        }

        // Facial discs
        for sign: CGFloat in [-1, 1] {
            let discR = s * 0.28
            context.fill(
                Path(ellipseIn: CGRect(
                    x: center.x + sign * s * 0.18 - discR,
                    y: center.y - s * 0.28 - discR * 0.85,
                    width: discR * 2,
                    height: discR * 1.85
                )),
                with: .color(cream)
            )
        }

        // Eyes + beak (readable from sapling onward)
        let eyeR = max(2.2, s * 0.15)
        for sign: CGFloat in [-1, 1] {
            let ec = CGPoint(x: center.x + sign * s * 0.18, y: center.y - s * 0.12)
            context.fill(
                Path(ellipseIn: CGRect(x: ec.x - eyeR, y: ec.y - eyeR, width: eyeR * 2, height: eyeR * 2)),
                with: .color(Color.white.opacity(wilted ? 0.55 : 0.98))
            )
            // Soft ring
            let ring = eyeR * 0.78
            context.stroke(
                Path(ellipseIn: CGRect(x: ec.x - ring, y: ec.y - ring, width: ring * 2, height: ring * 2)),
                with: .color(furDeep.opacity(0.35)),
                lineWidth: max(0.8, s * 0.02)
            )
            let pupil = eyeR * 0.55
            context.fill(
                Path(ellipseIn: CGRect(x: ec.x - pupil, y: ec.y - pupil, width: pupil * 2, height: pupil * 2)),
                with: .color(ink)
            )
            let hi = max(0.8, pupil * 0.35)
            context.fill(
                Path(ellipseIn: CGRect(
                    x: ec.x - pupil * 0.25,
                    y: ec.y - pupil * 0.45,
                    width: hi,
                    height: hi
                )),
                with: .color(Color.white.opacity(wilted ? 0.35 : 0.8))
            )
        }

        var beak = Path()
        let by = center.y + s * 0.02
        beak.move(to: CGPoint(x: center.x, y: by - s * 0.02))
        beak.addQuadCurve(
            to: CGPoint(x: center.x + s * 0.09, y: by + s * 0.12),
            control: CGPoint(x: center.x + s * 0.1, y: by + s * 0.02)
        )
        beak.addQuadCurve(
            to: CGPoint(x: center.x - s * 0.09, y: by + s * 0.12),
            control: CGPoint(x: center.x, y: by + s * 0.18)
        )
        beak.addQuadCurve(
            to: CGPoint(x: center.x, y: by - s * 0.02),
            control: CGPoint(x: center.x - s * 0.1, y: by + s * 0.02)
        )
        beak.closeSubpath()
        context.fill(beak, with: .color(beakColor))
    }

    /// Fox in a leafy nest — tall ears, tapered snout, white blaze.
    private func drawFox(
        in context: inout GraphicsContext,
        center: CGPoint,
        plantHeight: CGFloat,
        width: CGFloat
    ) {
        drawAnimalCanopyFoliage(in: &context, center: center, plantHeight: plantHeight)

        let s = plantHeight * (stage == .sapling ? 0.32 : 0.40)
        let o = wilted ? 0.78 : 1.0
        let fur = palette.leafMain.opacity(o)
        let furDeep = palette.leafDark.opacity(o)
        let cream = Color.white.opacity(wilted ? 0.5 : 0.96)
        let blush = palette.leafLight.opacity(wilted ? 0.5 : 0.88)
        let ink = palette.trunk.opacity(wilted ? 0.75 : 0.92)

        // Ears behind the head — tall, slightly outward.
        for sign: CGFloat in [-1, 1] {
            var ear = Path()
            ear.move(to: CGPoint(x: center.x + sign * s * 0.06, y: center.y - s * 0.16))
            ear.addQuadCurve(
                to: CGPoint(x: center.x + sign * s * 0.36, y: center.y - s * 0.82),
                control: CGPoint(x: center.x + sign * s * 0.08, y: center.y - s * 0.55)
            )
            ear.addQuadCurve(
                to: CGPoint(x: center.x + sign * s * 0.50, y: center.y - s * 0.10),
                control: CGPoint(x: center.x + sign * s * 0.58, y: center.y - s * 0.48)
            )
            ear.closeSubpath()
            context.fill(ear, with: .color(fur))

            var rim = Path()
            rim.move(to: CGPoint(x: center.x + sign * s * 0.14, y: center.y - s * 0.18))
            rim.addLine(to: CGPoint(x: center.x + sign * s * 0.36, y: center.y - s * 0.72))
            rim.addLine(to: CGPoint(x: center.x + sign * s * 0.44, y: center.y - s * 0.16))
            rim.closeSubpath()
            context.fill(rim, with: .color(furDeep.opacity(0.55)))

            var inner = Path()
            inner.move(to: CGPoint(x: center.x + sign * s * 0.16, y: center.y - s * 0.20))
            inner.addQuadCurve(
                to: CGPoint(x: center.x + sign * s * 0.34, y: center.y - s * 0.62),
                control: CGPoint(x: center.x + sign * s * 0.18, y: center.y - s * 0.42)
            )
            inner.addQuadCurve(
                to: CGPoint(x: center.x + sign * s * 0.40, y: center.y - s * 0.18),
                control: CGPoint(x: center.x + sign * s * 0.42, y: center.y - s * 0.38)
            )
            inner.closeSubpath()
            context.fill(inner, with: .color(blush))
        }

        // Head silhouette: wide cheeks tapering to a pointed muzzle.
        var head = Path()
        head.move(to: CGPoint(x: center.x, y: center.y - s * 0.30))
        head.addQuadCurve(
            to: CGPoint(x: center.x + s * 0.54, y: center.y + s * 0.02),
            control: CGPoint(x: center.x + s * 0.56, y: center.y - s * 0.22)
        )
        head.addQuadCurve(
            to: CGPoint(x: center.x, y: center.y + s * 0.50),
            control: CGPoint(x: center.x + s * 0.30, y: center.y + s * 0.44)
        )
        head.addQuadCurve(
            to: CGPoint(x: center.x - s * 0.54, y: center.y + s * 0.02),
            control: CGPoint(x: center.x - s * 0.30, y: center.y + s * 0.44)
        )
        head.addQuadCurve(
            to: CGPoint(x: center.x, y: center.y - s * 0.30),
            control: CGPoint(x: center.x - s * 0.56, y: center.y - s * 0.22)
        )
        head.closeSubpath()
        context.fill(head, with: .color(fur))

        // White cheek patches + muzzle blaze.
        for sign: CGFloat in [-1, 1] {
            var cheek = Path()
            cheek.move(to: CGPoint(x: center.x + sign * s * 0.06, y: center.y + s * 0.02))
            cheek.addQuadCurve(
                to: CGPoint(x: center.x + sign * s * 0.46, y: center.y + s * 0.06),
                control: CGPoint(x: center.x + sign * s * 0.28, y: center.y - s * 0.06)
            )
            cheek.addQuadCurve(
                to: CGPoint(x: center.x + sign * s * 0.10, y: center.y + s * 0.36),
                control: CGPoint(x: center.x + sign * s * 0.40, y: center.y + s * 0.28)
            )
            cheek.addQuadCurve(
                to: CGPoint(x: center.x + sign * s * 0.06, y: center.y + s * 0.02),
                control: CGPoint(x: center.x + sign * s * 0.02, y: center.y + s * 0.20)
            )
            cheek.closeSubpath()
            context.fill(cheek, with: .color(cream))
        }

        var blaze = Path()
        blaze.move(to: CGPoint(x: center.x, y: center.y - s * 0.02))
        blaze.addQuadCurve(
            to: CGPoint(x: center.x + s * 0.16, y: center.y + s * 0.22),
            control: CGPoint(x: center.x + s * 0.14, y: center.y + s * 0.06)
        )
        blaze.addQuadCurve(
            to: CGPoint(x: center.x, y: center.y + s * 0.46),
            control: CGPoint(x: center.x + s * 0.12, y: center.y + s * 0.40)
        )
        blaze.addQuadCurve(
            to: CGPoint(x: center.x - s * 0.16, y: center.y + s * 0.22),
            control: CGPoint(x: center.x - s * 0.12, y: center.y + s * 0.40)
        )
        blaze.addQuadCurve(
            to: CGPoint(x: center.x, y: center.y - s * 0.02),
            control: CGPoint(x: center.x - s * 0.14, y: center.y + s * 0.06)
        )
        blaze.closeSubpath()
        context.fill(blaze, with: .color(cream))

        let eyeW = max(2.2, s * 0.13)
        let eyeH = max(1.8, s * 0.09)
        for sign: CGFloat in [-1, 1] {
            let ec = CGPoint(x: center.x + sign * s * 0.18, y: center.y - s * 0.02)
            var brow = Path()
            brow.move(to: CGPoint(x: ec.x - sign * eyeW * 0.55, y: ec.y - eyeH * 0.85))
            brow.addQuadCurve(
                to: CGPoint(x: ec.x + sign * eyeW * 0.65, y: ec.y - eyeH * 0.55),
                control: CGPoint(x: ec.x + sign * eyeW * 0.1, y: ec.y - eyeH * 1.15)
            )
            brow.addQuadCurve(
                to: CGPoint(x: ec.x - sign * eyeW * 0.55, y: ec.y - eyeH * 0.85),
                control: CGPoint(x: ec.x + sign * eyeW * 0.05, y: ec.y - eyeH * 0.7)
            )
            context.fill(brow, with: .color(furDeep.opacity(0.7)))

            var eye = Path()
            eye.move(to: CGPoint(x: ec.x - eyeW, y: ec.y))
            eye.addQuadCurve(
                to: CGPoint(x: ec.x + eyeW, y: ec.y),
                control: CGPoint(x: ec.x, y: ec.y - eyeH)
            )
            eye.addQuadCurve(
                to: CGPoint(x: ec.x - eyeW, y: ec.y),
                control: CGPoint(x: ec.x, y: ec.y + eyeH * 0.85)
            )
            eye.closeSubpath()
            context.fill(eye, with: .color(ink))

            let hi = max(0.8, eyeW * 0.28)
            context.fill(
                Path(ellipseIn: CGRect(
                    x: ec.x - sign * eyeW * 0.15 - hi * 0.2,
                    y: ec.y - eyeH * 0.45,
                    width: hi,
                    height: hi
                )),
                with: .color(Color.white.opacity(wilted ? 0.35 : 0.75))
            )
        }

        var nose = Path()
        let ny = center.y + s * 0.28
        nose.move(to: CGPoint(x: center.x, y: ny - s * 0.04))
        nose.addQuadCurve(
            to: CGPoint(x: center.x + s * 0.08, y: ny + s * 0.06),
            control: CGPoint(x: center.x + s * 0.08, y: ny)
        )
        nose.addQuadCurve(
            to: CGPoint(x: center.x - s * 0.08, y: ny + s * 0.06),
            control: CGPoint(x: center.x, y: ny + s * 0.1)
        )
        nose.addQuadCurve(
            to: CGPoint(x: center.x, y: ny - s * 0.04),
            control: CGPoint(x: center.x - s * 0.08, y: ny)
        )
        nose.closeSubpath()
        context.fill(nose, with: .color(ink))
    }

    private func drawFruit(
        in context: inout GraphicsContext,
        center: CGPoint,
        plantHeight: CGFloat,
        width: CGFloat
    ) {
        let spots: [(CGFloat, CGFloat)] = [
            (-0.12, 0.02), (0.14, -0.04), (-0.02, 0.14), (0.1, 0.12), (-0.16, 0.1)
        ]
        let count = size == .chip ? 3 : (size == .bed ? 4 : 5)
        let baseR = max(2.0, plantHeight * (size == .chip ? 0.07 : 0.085))
        let scale = 0.35 + 0.65 * CGFloat(bloom)
        for (i, spot) in spots.prefix(count).enumerated() {
            let stagger = min(1, max(0, bloom * 1.35 - Double(i) * 0.12))
            let r = baseR * scale * CGFloat(0.55 + 0.45 * stagger)
            guard r > 0.8 else { continue }
            let c = leafPoint(center: center, plantHeight: plantHeight, dx: spot.0, dy: spot.1)
            let rect = CGRect(x: c.x - r / 2, y: c.y - r / 2, width: r, height: r)
            context.fill(
                Path(ellipseIn: rect),
                with: .color(palette.fruit.opacity(0.55 + 0.45 * stagger))
            )
            let hi = Path(ellipseIn: CGRect(
                x: rect.minX + r * 0.22,
                y: rect.minY + r * 0.18,
                width: r * 0.28,
                height: r * 0.22
            ))
            context.fill(hi, with: .color(Color.white.opacity(0.35 * stagger)))
        }
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
    var fruit: Color

    private static func base(
        leafMain: Color,
        leafLight: Color,
        leafDark: Color,
        trunk: Color,
        fruit: Color = Color(hex: "E8913A")
    ) -> SpeciesPalette {
        SpeciesPalette(
            leafMain: leafMain,
            leafLight: leafLight,
            leafDark: leafDark,
            trunk: trunk,
            potTop: GroveTheme.pot,
            potBottom: GroveTheme.potRim,
            potRim: Color(hex: "9A7A55"),
            soil: GroveTheme.soil,
            fruit: fruit
        )
    }

    private static func wiltedBase(
        leafMain: Color,
        leafLight: Color,
        leafDark: Color,
        fruit: Color = Color(hex: "B89A78")
    ) -> SpeciesPalette {
        SpeciesPalette(
            leafMain: leafMain,
            leafLight: leafLight,
            leafDark: leafDark,
            trunk: Color(hex: "7A6A58"),
            potTop: GroveTheme.wiltSoil,
            potBottom: Color(hex: "7A6B5A"),
            potRim: Color(hex: "6E6358"),
            soil: Color(hex: "5C534A"),
            fruit: fruit
        )
    }

    static func forSpecies(_ id: String, wilted: Bool) -> SpeciesPalette {
        // Wilted keeps a faint species tint so beds stay distinguishable.
        if wilted {
            switch id {
            case "sakura":
                return .wiltedBase(
                    leafMain: Color(hex: "C4B0B6"),
                    leafLight: Color(hex: "D4C6CB"),
                    leafDark: Color(hex: "A8989E")
                )
            case "maple":
                return .wiltedBase(
                    leafMain: Color(hex: "B8A090"),
                    leafLight: Color(hex: "C8B4A4"),
                    leafDark: Color(hex: "9A8678")
                )
            case "pine":
                return .wiltedBase(
                    leafMain: Color(hex: "9AA898"),
                    leafLight: Color(hex: "B0BAAE"),
                    leafDark: Color(hex: "7E8A7C")
                )
            case "ginkgo":
                return .wiltedBase(
                    leafMain: Color(hex: "C4B896"),
                    leafLight: Color(hex: "D4C8A8"),
                    leafDark: Color(hex: "A89870")
                )
            case "orange":
                return .wiltedBase(
                    leafMain: Color(hex: "9AAA88"),
                    leafLight: Color(hex: "B0B89A"),
                    leafDark: Color(hex: "7E8A70"),
                    fruit: Color(hex: "C4A070")
                )
            case "lemon":
                return .wiltedBase(
                    leafMain: Color(hex: "A0AA88"),
                    leafLight: Color(hex: "B8C09A"),
                    leafDark: Color(hex: "849070"),
                    fruit: Color(hex: "C8C090")
                )
            default:
                return .wiltedBase(
                    leafMain: GroveTheme.wiltLeaf,
                    leafLight: Color(hex: "B8BCAE"),
                    leafDark: Color(hex: "8A8E80")
                )
            }
        }
        switch id {
        case "pine":
            return .base(
                leafMain: Color(hex: "2F5D3A"),
                leafLight: Color(hex: "4A7A52"),
                leafDark: Color(hex: "1F3F28"),
                trunk: Color(hex: "5C4033")
            )
        case "sakura":
            return .base(
                leafMain: Color(hex: "E8A0B5"),
                leafLight: Color(hex: "F3C4D0"),
                leafDark: Color(hex: "C97890"),
                trunk: Color(hex: "6B5344")
            )
        case "peony", "rose", "willow":
            return .base(
                leafMain: Color(hex: "2F6B3A"),
                leafLight: Color(hex: "F6B3C8"),
                leafDark: Color(hex: "9B2D4A"),
                trunk: Color(hex: "3F6A3A"),
                fruit: Color(hex: "E85A7A")
            )
        case "owl":
            return .base(
                leafMain: Color(hex: "7A6544"),
                leafLight: Color(hex: "E8D7B0"),
                leafDark: Color(hex: "4A3A26"),
                trunk: Color(hex: "2A2218"),
                fruit: Color(hex: "E8A030")
            )
        case "fox":
            return .base(
                leafMain: Color(hex: "E86A24"),
                leafLight: Color(hex: "F4A88A"),
                leafDark: Color(hex: "A84212"),
                trunk: Color(hex: "2E2118"),
                fruit: Color(hex: "E86A24")
            )
        case "maple":
            return .base(
                leafMain: Color(hex: "C45C26"),
                leafLight: Color(hex: "E08A4A"),
                leafDark: Color(hex: "8F3B15"),
                trunk: Color(hex: "5C4033")
            )
        case "baobab":
            return .base(
                leafMain: Color(hex: "6B8F3C"),
                leafLight: Color(hex: "8FB35A"),
                leafDark: Color(hex: "4A6A28"),
                trunk: Color(hex: "8B7355")
            )
        case "ginkgo":
            return .base(
                leafMain: Color(hex: "D4A017"),
                leafLight: Color(hex: "E8C04A"),
                leafDark: Color(hex: "B07A10"),
                trunk: Color(hex: "6B5344")
            )
        case "orange":
            return .base(
                leafMain: Color(hex: "3F7A3A"),
                leafLight: Color(hex: "5C9A52"),
                leafDark: Color(hex: "2A5A28"),
                trunk: Color(hex: "6B5344"),
                fruit: Color(hex: "F08C2E")
            )
        case "lemon":
            return .base(
                leafMain: Color(hex: "4A8A3E"),
                leafLight: Color(hex: "6AAA58"),
                leafDark: Color(hex: "326A2A"),
                trunk: Color(hex: "6B5344"),
                fruit: Color(hex: "F0D24A")
            )
        default: // oak
            return .base(
                leafMain: GroveTheme.moss,
                leafLight: GroveTheme.leafLight,
                leafDark: GroveTheme.mossDeep,
                trunk: GroveTheme.soil
            )
        }
    }
}
