import SwiftUI
import SwiftData

struct PlantingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsRows: [AppSettings]
    @Query(sort: \FocusTag.createdAt) private var tags: [FocusTag]

    @Bindable var engine: SessionEngine
    var store: StoreService
    var onViewGrove: (() -> Void)?

    @State private var durationSec: Int = 25 * 60
    @State private var speciesId: String = "oak"
    @State private var tagId: UUID?
    @State private var showPaywall = false
    @State private var showSettings = false
    @State private var plantPressed = false

    private var settings: AppSettings? { settingsRows.first }
    private var unlocked: Bool {
        settings?.lifetimeUnlocked == true || store.hasLifetimeEntitlement
    }

    private var isActive: Bool { engine.active != nil }
    private var wiltVisual: Bool {
        engine.isInGrace || (engine.active?.wilted == true)
    }

    private var sessionProgress: Double {
        guard let session = engine.active else { return 0.28 }
        let total = max(session.durationSec, 1)
        return 1 - (Double(engine.secondsLeft) / Double(total))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DeskPaperBackground(wilted: wiltVisual && isActive)

                VStack(spacing: 0) {
                    if isActive {
                        activePane
                    } else {
                        idlePane
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)

                if let outcome = engine.pendingOutcome {
                    SessionOutcomeCard(
                        outcome: outcome,
                        onContinue: {
                            withAnimation(.easeOut(duration: 0.22)) {
                                engine.dismissOutcome()
                            }
                        },
                        onViewGrove: {
                            engine.dismissOutcome()
                            onViewGrove?()
                        }
                    )
                    .transition(.opacity)
                    .zIndex(10)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    if !isActive {
                        Text("Grove")
                            .font(.system(.headline, design: .serif).weight(.semibold))
                            .foregroundStyle(GroveTheme.ink)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if !isActive {
                        HStack(spacing: 12) {
                            if !unlocked {
                                Button("Unlock") { showPaywall = true }
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(GroveTheme.moss)
                            }
                            Button {
                                showSettings = true
                            } label: {
                                Image(systemName: "gearshape")
                                    .foregroundStyle(GroveTheme.inkMuted)
                            }
                            .accessibilityLabel("Settings")
                        }
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .sheet(isPresented: $showPaywall) {
                PaywallView(store: store) {
                    settings?.lifetimeUnlocked = true
                    try? modelContext.save()
                    showPaywall = false
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(store: store)
            }
            .onChange(of: durationSec) { _, value in
                settings?.defaultDurationSec = value
                try? modelContext.save()
            }
            .onChange(of: store.hasLifetimeEntitlement) { _, value in
                if value {
                    settings?.lifetimeUnlocked = true
                    try? modelContext.save()
                }
            }
            .task {
                await NotificationService.requestPermissionIfNeeded()
            }
            .onAppear {
                if let d = settings?.defaultDurationSec {
                    durationSec = d
                }
                ensureValidTagSelection()
            }
            .onChange(of: tags.map(\.id)) { _, _ in
                ensureValidTagSelection()
            }
        }
    }

    // MARK: - Idle (desk setup)

    private var idlePane: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 4)

            // Dial + current time + pot
            ZStack {
                DurationDialView(durationSec: $durationSec)
                    .frame(width: 300, height: 300)
                    .opacity(0.95)

                VStack(spacing: 2) {
                    HStack(alignment: .lastTextBaseline, spacing: 3) {
                        Text("\(durationSec / 60)")
                            .font(.system(size: 42, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .contentTransition(.numericText())
                        Text("min")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(GroveTheme.inkMuted)
                            .padding(.bottom, 4)
                    }
                    .foregroundStyle(GroveTheme.ink)
                    .animation(.snappy(duration: 0.2), value: durationSec)

                    TreeGrowthView(
                        progress: 0.32,
                        wilted: false,
                        speciesName: TreeCatalog.species(id: speciesId)?.localizedName ?? String(localized: "Tree"),
                        speciesId: speciesId,
                        compact: true
                    )
                    .frame(width: 118, height: 126)
                }
                .offset(y: 10)
                .allowsHitTesting(false)
            }
            .frame(height: 300)

            HStack(spacing: 6) {
                Image(systemName: "hand.draw")
                    .font(.caption)
                Text("Drag the knob · 1–90 min")
                    .font(.caption.weight(.medium))
            }
            .foregroundStyle(GroveTheme.inkMuted)

            Text(TreeCatalog.species(id: speciesId)?.localizedName ?? String(localized: "Tree"))
                .font(.system(.title3, design: .serif).weight(.medium))
                .foregroundStyle(GroveTheme.ink)

            speciesRow

            tagChips

            Spacer(minLength: 8)

            plantButton

            Text("While you focus, this pot grows. Finish → Grove. Leave → it wilts.")
                .font(.caption)
                .foregroundStyle(GroveTheme.inkMuted)
                .multilineTextAlignment(.center)
                .padding(.bottom, 6)
        }
    }

    private var speciesRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TreeCatalog.all) { s in
                    let locked = !s.isFree && !unlocked
                    Button {
                        if locked {
                            showPaywall = true
                        } else {
                            withAnimation(.easeInOut(duration: 0.2)) { speciesId = s.id }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            TreeArt(
                                speciesId: s.id,
                                progress: 0.75,
                                wilted: false,
                                size: .chip
                            )
                            .frame(width: 22, height: 26)
                            Text(s.localizedName)
                            if locked {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 9))
                            }
                        }
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(speciesId == s.id ? GroveTheme.chipSelected : GroveTheme.chipFill)
                        )
                        .foregroundStyle(speciesId == s.id ? Color.white : GroveTheme.ink)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private var tagChips: some View {
        Group {
            if !tags.isEmpty {
                HStack(spacing: 8) {
                    ForEach(tags, id: \.id) { tag in
                        let selected = tag.id == tagId
                        Button {
                            tagId = tag.id
                        } label: {
                            Text(LocalizedStringKey(tag.name))
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .strokeBorder(
                                            selected ? GroveTheme.moss : GroveTheme.ink.opacity(0.15),
                                            lineWidth: selected ? 1.5 : 1
                                        )
                                        .background(Capsule().fill(selected ? GroveTheme.moss.opacity(0.1) : .clear))
                                )
                                .foregroundStyle(selected ? GroveTheme.mossDeep : GroveTheme.inkMuted)
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private var plantButton: some View {
        Button {
            start()
        } label: {
            Text("Plant & Focus")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(GroveTheme.mossDeep)
                        .shadow(color: GroveTheme.moss.opacity(0.35), radius: 12, y: 6)
                )
                .foregroundStyle(.white)
                .scaleEffect(plantPressed ? 0.97 : 1)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in plantPressed = true }
                .onEnded { _ in plantPressed = false }
        )
    }

    // MARK: - Active (immersive)

    private var activePane: some View {
        let activeSpecies = engine.active?.speciesId ?? speciesId
        let progress = max(0.08, sessionProgress)
        let stage = TreeStage.from(progress: progress, wilted: wiltVisual)

        return VStack(spacing: 0) {
            Spacer(minLength: 12)

            // Tree above timer. Clip only below the art so digits stay clean;
            // TreeArt itself is allowed to use the full frame height (no fake top gap).
            TreeGrowthView(
                progress: progress,
                wilted: wiltVisual,
                speciesName: TreeCatalog.species(id: activeSpecies)?.localizedName ?? String(localized: "Tree"),
                speciesId: activeSpecies
            )
            .frame(maxWidth: 280)
            .frame(height: 268)
            .frame(maxWidth: .infinity)
            .compositingGroup()
            .clipped()

            Text(timeString(engine.secondsLeft))
                .font(GroveTheme.timerFont)
                .monospacedDigit()
                .foregroundStyle(GroveTheme.ink.opacity(wiltVisual ? 0.45 : 0.7))
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
                .animation(.easeInOut(duration: 0.35), value: wiltVisual)

            VStack(spacing: 6) {
                Text(stage.localizedTitle)
                    .font(.system(.headline, design: .serif).weight(.semibold))
                    .foregroundStyle(wiltVisual ? GroveTheme.wiltLeaf : GroveTheme.mossDeep)
                    .contentTransition(.numericText())

                if engine.isInGrace {
                    Text("Come back — wilting in \(engine.graceSecondsLeft)s")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color(hex: "B45309"))
                } else {
                    Text("Tree grows as time passes — stay until it’s fully grown")
                        .font(.caption)
                        .foregroundStyle(GroveTheme.inkMuted)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.top, 10)
            .animation(.easeInOut(duration: 0.3), value: stage)

            Button("Cancel") {
                NotificationService.cancelSessionEnd()
                engine.cancelActive()
                try? modelContext.save()
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(GroveTheme.inkMuted)
            .padding(.top, 16)
            .padding(.bottom, 10)

            Spacer(minLength: 4)
        }
        .animation(.easeInOut(duration: 0.35), value: engine.isInGrace)
    }

    // MARK: - Helpers

    private func ensureValidTagSelection() {
        if let tagId, tags.contains(where: { $0.id == tagId }) { return }
        tagId = tags.first?.id
    }

    private func start() {
        let session = FocusSession(
            durationSec: durationSec,
            speciesId: speciesId,
            tagId: tagId
        )
        modelContext.insert(session)
        try? modelContext.save()
        engine.start(session: session, graceSec: settings?.graceSec ?? 5)
        NotificationService.scheduleSessionEnd(
            at: session.plannedEndAt,
            durationMinutes: durationSec / 60
        )
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func timeString(_ sec: Int) -> String {
        let m = sec / 60
        let s = sec % 60
        return String(format: "%d:%02d", m, s)
    }
}
