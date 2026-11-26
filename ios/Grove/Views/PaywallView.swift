import SwiftUI

struct PaywallView: View {
    var store: StoreService
    var onUnlocked: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("Buy once. Yours forever.")
                    .font(.system(.title, design: .serif).weight(.bold))
                    .foregroundStyle(GroveTheme.ink)

                Text("No subscription. Unlock every tree species and full focus history.")
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 10) {
                    labelRow("All tree species")
                    labelRow("Month & Year stats")
                    labelRow("No ads, no account")
                }
                .padding(.vertical, 8)

                Group {
                    if let product = store.products.first {
                        Text(product.displayPrice)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(GroveTheme.ink)
                    } else if store.lastError != nil {
                        Text("Price unavailable")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(GroveTheme.inkMuted)
                        Text("Check your connection and try again.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ProgressView()
                            .padding(.vertical, 4)
                    }
                }

                if let err = store.lastError {
                    Text(err)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                Button {
                    Task {
                        if await store.purchaseLifetime() {
                            onUnlocked()
                        }
                    }
                } label: {
                    Group {
                        if store.isPurchasing {
                            ProgressView()
                        } else {
                            Text("Unlock Lifetime")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .buttonStyle(.borderedProminent)
                .tint(GroveTheme.mossDeep)
                .disabled(store.isPurchasing || store.products.isEmpty)

                Button("Restore Purchases") {
                    Task {
                        await store.restore()
                        if store.hasLifetimeEntitlement {
                            onUnlocked()
                        }
                    }
                }
                .frame(maxWidth: .infinity)

                Spacer()
            }
            .padding()
            .background(DeskPaperBackground())
            .navigationTitle("Lifetime")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task { await store.refreshProducts() }
        }
    }

    private func labelRow(_ text: String) -> some View {
        Label(text, systemImage: "checkmark.circle.fill")
            .foregroundStyle(GroveTheme.moss)
    }
}
