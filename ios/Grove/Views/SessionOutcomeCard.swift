import SwiftUI

/// Full-screen outcome card for grown or wilted sessions.
struct SessionOutcomeCard: View {
    let outcome: SessionOutcome
    var onContinue: () -> Void
    var onViewGrove: () -> Void

    @State private var appeared = false
    @State private var fruitBloom = 0.0

    private var species: TreeSpecies? {
        TreeCatalog.species(id: outcome.speciesId)
    }

    private var speciesName: String {
        species?.localizedName ?? String(localized: "Tree")
    }

    private var isGrown: Bool { outcome.kind == .grown }

    private var outcomeSubtitle: String {
        if !isGrown {
            return String(localized: "You left too long — this tree wilted in your Grove")
        }
        switch outcome.speciesId {
        case "orange":
            return String(localized: "Oranges ripened on your tree")
        case "lemon":
            return String(localized: "Lemons ripened on your tree")
        default:
            return String(
                localized: "\(outcome.durationSec / 60) min focus · planted in your Grove"
            )
        }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(appeared ? 0.38 : 0)
                .ignoresSafeArea()
                .onTapGesture { onContinue() }

            VStack(spacing: 0) {
                Spacer(minLength: 16)

                VStack(spacing: 10) {
                    Text(isGrown ? String(localized: "Fully grown") : String(localized: "Wilted"))
                        .font(.system(.title2, design: .serif).weight(.semibold))
                        .foregroundStyle(GroveTheme.ink)
                        .padding(.bottom, 2)

                    // Taller well so canopy tips aren't shaved; clip only the art bounds.
                    TreeArt(
                        speciesId: outcome.speciesId,
                        progress: isGrown ? 1 : 0.55,
                        wilted: !isGrown,
                        size: .hero,
                        fruitBloom: isGrown ? fruitBloom : 0
                    )
                    .frame(width: 168, height: 188)
                    .frame(maxWidth: .infinity)
                    .compositingGroup()
                    .clipped()
                    .scaleEffect(appeared ? 1 : 0.92)
                    .opacity(appeared ? 1 : 0.85)

                    VStack(spacing: 6) {
                        Text(speciesName)
                            .font(.system(.title3, design: .serif).weight(.medium))
                            .foregroundStyle(GroveTheme.ink)

                        Text(outcomeSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(GroveTheme.inkMuted)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 2)

                    VStack(spacing: 10) {
                        Button(action: onViewGrove) {
                            Text("View in Grove")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(isGrown ? GroveTheme.mossDeep : GroveTheme.ink.opacity(0.82))
                                )
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)

                        Button(
                            isGrown ? String(localized: "Plant another") : String(localized: "Try again"),
                            action: onContinue
                        )
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(isGrown ? GroveTheme.mossDeep : GroveTheme.inkMuted)
                            .padding(.top, 2)
                    }
                    .padding(.top, 6)
                }
                .padding(.horizontal, 22)
                .padding(.top, 22)
                .padding(.bottom, 24)
                .frame(maxWidth: 340)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(GroveTheme.paperTop)
                        .shadow(color: .black.opacity(0.18), radius: 28, y: 14)
                )
                .padding(.horizontal, 28)
                .scaleEffect(appeared ? 1 : 0.94)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)

                Spacer(minLength: 16)
            }
        }
        .onAppear {
            if isGrown {
                CompletionFeedback.playSuccess()
            } else {
                CompletionFeedback.playWilt()
            }
            withAnimation(.spring(response: 0.48, dampingFraction: 0.78)) {
                appeared = true
            }
            if isGrown, species?.bearsFruit == true {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.62).delay(0.28)) {
                    fruitBloom = 1
                }
            } else if isGrown {
                fruitBloom = 1
            }
        }
        .accessibilityAddTraits(.isModal)
    }
}
