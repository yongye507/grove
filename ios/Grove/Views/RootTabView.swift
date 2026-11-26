import SwiftUI
import SwiftData

struct RootTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query private var settingsRows: [AppSettings]

    @State private var engine = SessionEngine()
    @State private var store = StoreService()
    @State private var didBootstrap = false
    @State private var selectedTab = 0

    private var graceSec: Int { settingsRows.first?.graceSec ?? 5 }

    var body: some View {
        TabView(selection: $selectedTab) {
            PlantingView(engine: engine, store: store, onViewGrove: {
                selectedTab = 1
            })
            .tabItem { Label("Plant", systemImage: "leaf.fill") }
            .tag(0)

            GroveView()
                .tabItem { Label("Grove", systemImage: "tree.fill") }
                .tag(1)

            StatsView(store: store)
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
                .tag(2)
        }
        .tint(GroveTheme.mossDeep)
        .task {
            store.start()
            guard !didBootstrap else { return }
            didBootstrap = true
            try? GroveStore.bootstrapIfNeeded(context: modelContext)
            engine.graceSec = graceSec
            engine.bind { _ in
                NotificationService.cancelSessionEnd()
                try? modelContext.save()
            }
            #if DEBUG
            engine.previewOutcomeIfRequested()
            #endif
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                engine.handleScenePhase(active: true, inBackground: false, graceSec: graceSec)
            case .background:
                engine.handleScenePhase(active: false, inBackground: true, graceSec: graceSec)
            case .inactive:
                // Control Center / banners — do not start wilt grace.
                break
            @unknown default:
                break
            }
        }
        .onChange(of: selectedTab) { _, tab in
            // Leaving Plant via tab bar dismisses an already-seen outcome so it
            // doesn't pop again when returning (e.g. after View in Grove).
            if tab != 0 {
                engine.dismissOutcome()
            }
        }
        .onChange(of: graceSec) { _, value in
            engine.graceSec = value
        }
        .onDisappear {
            store.stop()
            engine.stopLifecycleObservers()
        }
    }
}
