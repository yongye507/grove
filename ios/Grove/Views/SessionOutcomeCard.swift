import SwiftUI

/// Full-screen outcome card for grown or wilted sessions.
struct SessionOutcomeCard: View {
    let outcome: SessionOutcome
    var onContinue: () -> Void
    var onViewGrove: () -> Void

    @State private var appeared = false

    private var speciesName: String {
        TreeCatalog.species(id: outcome.speciesId)?.name ?? "Tree"
    }

    private var isGrown: Bool { outcome.kind == .grown }

    var body: some View {
        ZStack {
            Color.black.opacity(appeared ? 0.38 : 0)
                .ignoresSafeArea()
                .onTapGesture { onContinue() }

            VStack(spacing: 0) {
                Spacer(minLength: 16)

                VStack(spacing: 12) {
                    Text(isGrown ? "Fully grown" : "Wilted")
                        .font(.system(.title2, design: .serif).weight(.semibold))
                        .foregroundStyle(GroveTheme.ink)

                    // Fixed well — no scaleEffect (that escaped the clip and covered the title).
                    TreeArt(
                        speciesId: outcome.speciesId,
                        progress: isGrown ? 1 : 0.55,
                        wilted: !isGrown,
                        size: .hero
                    )
                    .frame(width: 150, height: 158)
                    .frame(maxWidth: .infinity)
                    .compositingGroup()
                    .clipped()
                    .padding(.top, 4)
                    .scaleEffect(appeared ? 1 : 0.92)
                    .opacity(appeared ? 1 : 0.85)

                    VStack(spacing: 6) {
                        Text(speciesName)
                            .font(.system(.title3, design: .serif).weight(.medium))
                            .foregroundStyle(GroveTheme.ink)

                        Text(
                            isGrown
                                ? "\(outcome.durationSec / 60) min focus · planted in your Grove"
                                : "You left too long — this tree wilted in your Grove"
                        )
                        .font(.subheadline)
                        .foregroundStyle(GroveTheme.inkMuted)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 4)

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

                        Button(isGrown ? "Plant another" : "Try again", action: onContinue)
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
        }
        .accessibilityAddTraits(.isModal)
    }
}
