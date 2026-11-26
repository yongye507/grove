import SwiftUI
import SwiftData

/// Minimal settings for 1.0: grace, restore, privacy, about.
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsRows: [AppSettings]

    var store: StoreService

    @State private var showPaywall = false
    @State private var restoreMessage: String?

    private var settings: AppSettings? { settingsRows.first }

    private var unlocked: Bool {
        settings?.lifetimeUnlocked == true || store.hasLifetimeEntitlement
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(v) (\(b))"
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Stepper(value: graceBinding, in: 3...20) {
                        HStack {
                            Text("Leave grace")
                            Spacer()
                            Text("\(settings?.graceSec ?? 5)s")
                                .foregroundStyle(GroveTheme.inkMuted)
                                .monospacedDigit()
                        }
                    }
                    Text("How long you can leave the app before the tree wilts.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Focus")
                }

                Section {
                    if unlocked {
                        Label("Lifetime unlocked", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(GroveTheme.moss)
                    } else {
                        Button("Unlock Lifetime") { showPaywall = true }
                    }
                    Button("Restore Purchases") {
                        Task {
                            await store.restore()
                            if store.hasLifetimeEntitlement {
                                settings?.lifetimeUnlocked = true
                                try? modelContext.save()
                                restoreMessage = String(localized: "Purchases restored.")
                            } else {
                                restoreMessage = String(localized: "No lifetime purchase found.")
                            }
                        }
                    }
                    if let restoreMessage {
                        Text(restoreMessage)
                            .font(.footnote)
                            .foregroundStyle(GroveTheme.inkMuted)
                    }
                } header: {
                    Text("Purchases")
                }

                Section {
                    NavigationLink("Privacy Policy") {
                        PrivacyPolicyView()
                    }
                    LabeledContent("Version", value: appVersion)
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .background(DeskPaperBackground())
            .sheet(isPresented: $showPaywall) {
                PaywallView(store: store) {
                    settings?.lifetimeUnlocked = true
                    try? modelContext.save()
                    showPaywall = false
                }
            }
            .onChange(of: store.hasLifetimeEntitlement) { _, value in
                if value {
                    settings?.lifetimeUnlocked = true
                    try? modelContext.save()
                }
            }
        }
    }

    private var graceBinding: Binding<Int> {
        Binding(
            get: { settings?.graceSec ?? 5 },
            set: { newValue in
                settings?.graceSec = newValue
                try? modelContext.save()
            }
        )
    }
}
