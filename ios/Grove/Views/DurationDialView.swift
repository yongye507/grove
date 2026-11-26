import SwiftUI

/// Continuous duration dial. Arc opens at the bottom (−135°…+135° from top).
/// Drag maps linearly to minutes (default 5…90, step 1). Major ticks are labels only.
struct DurationDialView: View {
    @Binding var durationSec: Int
    /// Inclusive minute range.
    var minMinutes: Int = 1
    var maxMinutes: Int = 90
    /// Snap step while dragging / on release.
    var stepMinutes: Int = 1
    /// Labeled reference marks only (any minute in range is still allowed).
    var majorTicks: [Int] = [1, 15, 25, 45, 60, 90]
    var wilted: Bool = false

    private let arcStart = -135.0
    private let arcEnd = 135.0

    @State private var isDragging = false
    @State private var dragAngle: Double?
    @State private var dragStartFinger: Double?
    @State private var dragStartThumb: Double?
    @State private var dragDidMove = false

    private var minutes: Int {
        clampMinutes(durationSec / 60)
    }

    private var thumbAngle: Double {
        dragAngle ?? angle(forMinutes: minutes)
    }

    private var labeledTicks: [Int] {
        majorTicks.filter { $0 >= minMinutes && $0 <= maxMinutes }
    }

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let labelPad: CGFloat = 26
            let ringSide = side - labelPad * 2
            let line = max(12.0, ringSide * 0.052)
            let radius = ringSide / 2
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)

            ZStack {
                Circle()
                    .trim(from: 0, to: (arcEnd - arcStart) / 360)
                    .stroke(GroveTheme.ink.opacity(0.1), style: StrokeStyle(lineWidth: line, lineCap: .round))
                    .rotationEffect(.degrees(-90 + arcStart))
                    .frame(width: ringSide, height: ringSide)

                Circle()
                    .trim(from: 0, to: max(0.001, (thumbAngle - arcStart) / 360))
                    .stroke(
                        AngularGradient(
                            colors: wilted
                                ? [GroveTheme.wiltLeaf, GroveTheme.inkMuted]
                                : [GroveTheme.leafLight, GroveTheme.moss],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: line, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90 + arcStart))
                    .frame(width: ringSide, height: ringSide)

                // Minor ticks every 5 minutes (no labels)
                ForEach(Array(stride(from: minMinutes, through: maxMinutes, by: 5)), id: \.self) { m in
                    let isMajor = labeledTicks.contains(m)
                    if !isMajor {
                        Capsule()
                            .fill(GroveTheme.ink.opacity(0.18))
                            .frame(width: 2, height: 6)
                            .offset(y: -(radius - line * 0.15))
                            .rotationEffect(.degrees(angle(forMinutes: m)))
                    }
                }

                // Major labeled ticks outside the ring
                ForEach(labeledTicks, id: \.self) { m in
                    let ang = angle(forMinutes: m)
                    let selected = minutes == m
                    let labelRadius = radius + line * 0.55 + 12

                    Capsule()
                        .fill(selected ? GroveTheme.moss : GroveTheme.ink.opacity(0.35))
                        .frame(width: 2.5, height: selected ? 10 : 8)
                        .offset(y: -(radius - 1))
                        .rotationEffect(.degrees(ang))

                    Text("\(m)")
                        .font(.system(size: selected ? 13 : 11, weight: selected ? .bold : .medium, design: .rounded))
                        .foregroundStyle(selected ? GroveTheme.mossDeep : GroveTheme.inkMuted)
                        .rotationEffect(.degrees(-ang))
                        .offset(y: -labelRadius)
                        .rotationEffect(.degrees(ang))
                }

                // Thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: line + 10, height: line + 10)
                    .shadow(color: .black.opacity(0.18), radius: 3, y: 1)
                    .overlay(
                        Circle()
                            .fill(GroveTheme.mossDeep)
                            .frame(width: line - 2, height: line - 2)
                    )
                    .overlay(
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(.white.opacity(0.9))
                            .rotationEffect(.degrees(90))
                    )
                    .scaleEffect(isDragging ? 1.14 : 1)
                    .offset(y: -radius)
                    .rotationEffect(.degrees(thumbAngle))
            }
            .frame(width: side, height: side)
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
            .highPriorityGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let finger = angleFromTopClockwise(value.location, center: center)

                        if !isDragging {
                            isDragging = true
                            dragDidMove = false
                            dragStartFinger = finger
                            dragStartThumb = angle(forMinutes: minutes)
                            dragAngle = dragStartThumb
                        }

                        guard let startFinger = dragStartFinger,
                              let startThumb = dragStartThumb else { return }

                        let delta = shortestDelta(from: startFinger, to: finger)
                        if abs(delta) > 4 {
                            dragDidMove = true
                        }

                        let nextAngle: Double
                        if dragDidMove {
                            nextAngle = clamp(startThumb + delta, lo: arcStart, hi: arcEnd)
                        } else {
                            nextAngle = startThumb
                        }

                        let nextMin = minutes(fromAngle: nextAngle)
                        var t = Transaction()
                        t.disablesAnimations = true
                        withTransaction(t) {
                            dragAngle = nextAngle
                            let nextSec = nextMin * 60
                            if nextSec != durationSec {
                                durationSec = nextSec
                                if nextMin % 5 == 0 || stepMinutes > 1 {
                                    UISelectionFeedbackGenerator().selectionChanged()
                                }
                            }
                        }
                    }
                    .onEnded { value in
                        let finger = angleFromTopClockwise(value.location, center: center)
                        let finalAngle: Double
                        if dragDidMove {
                            finalAngle = dragAngle ?? angle(forMinutes: minutes)
                        } else {
                            finalAngle = clampToArc(finger)
                        }
                        let snapped = minutes(fromAngle: finalAngle)
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                            durationSec = snapped * 60
                            dragAngle = nil
                            isDragging = false
                            dragStartFinger = nil
                            dragStartThumb = nil
                            dragDidMove = false
                        }
                    }
            )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Focus duration")
        .accessibilityValue("\(minutes) minutes")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                durationSec = clampMinutes(minutes + stepMinutes) * 60
            case .decrement:
                durationSec = clampMinutes(minutes - stepMinutes) * 60
            @unknown default:
                break
            }
        }
        .onAppear {
            durationSec = clampMinutes(durationSec / 60) * 60
        }
    }

    // MARK: - Mapping

    private func angle(forMinutes m: Int) -> Double {
        let span = Double(maxMinutes - minMinutes)
        guard span > 0 else { return arcStart }
        let t = Double(clampMinutes(m) - minMinutes) / span
        return arcStart + (arcEnd - arcStart) * t
    }

    private func minutes(fromAngle angle: Double) -> Int {
        let span = arcEnd - arcStart
        guard span > 0 else { return minMinutes }
        let t = (clamp(angle, lo: arcStart, hi: arcEnd) - arcStart) / span
        let raw = Double(minMinutes) + t * Double(maxMinutes - minMinutes)
        let stepped = Int((raw / Double(stepMinutes)).rounded()) * stepMinutes
        return clampMinutes(stepped)
    }

    private func clampMinutes(_ m: Int) -> Int {
        min(maxMinutes, max(minMinutes, m))
    }

    private func angleFromTopClockwise(_ point: CGPoint, center: CGPoint) -> Double {
        let dx = point.x - center.x
        let dy = point.y - center.y
        return atan2(dx, -dy) * 180 / .pi
    }

    private func clampToArc(_ angle: Double) -> Double {
        if angle >= arcStart && angle <= arcEnd {
            return angle
        }
        let distToStart = abs(shortestDelta(from: angle, to: arcStart))
        let distToEnd = abs(shortestDelta(from: angle, to: arcEnd))
        return distToStart <= distToEnd ? arcStart : arcEnd
    }

    private func clamp(_ value: Double, lo: Double, hi: Double) -> Double {
        min(hi, max(lo, value))
    }

    private func shortestDelta(from: Double, to: Double) -> Double {
        var d = to - from
        while d > 180 { d -= 360 }
        while d < -180 { d += 360 }
        return d
    }
}
