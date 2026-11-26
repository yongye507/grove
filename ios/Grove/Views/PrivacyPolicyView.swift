import SwiftUI

/// In-app privacy policy. Host the same text at a public URL for App Store Connect.
struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy Policy")
                    .font(.system(.title2, design: .serif).weight(.semibold))
                    .foregroundStyle(GroveTheme.ink)

                Text("Last updated: November 26, 2026")
                    .font(.caption)
                    .foregroundStyle(GroveTheme.inkMuted)

                section(
                    "Overview",
                    "Grove is a focus timer that grows a tree while you stay present. We designed Grove to work without an account and without tracking you."
                )
                section(
                    "Data we store on your device",
                    "Focus sessions (time, tree species, tags, grown or wilted), your settings (default duration, leave-grace seconds), and whether you unlocked Lifetime are saved locally with Apple’s on-device storage (SwiftData / similar). This data stays on your device unless you back up or transfer the device with your own Apple tools."
                )
                section(
                    "Data we do not collect",
                    "We do not run analytics SDKs, do not use advertising identifiers, do not sell personal data, and do not require an account or email. Grove does not send your focus history to our servers because we do not operate a Grove cloud for this app."
                )
                section(
                    "Purchases",
                    "Lifetime unlock is processed by Apple through StoreKit / App Store. Apple handles payment details under Apple’s privacy policy. Grove only receives an entitlement signal that you own the product so locked trees and Month/Year stats can unlock on this device (and restore on your other devices signed into the same Apple ID)."
                )
                section(
                    "Notifications",
                    "If you allow notifications, Grove may schedule a local alert when a focus session is due to finish. Notification permission is optional and managed in iOS Settings."
                )
                section(
                    "Children",
                    "Grove does not target children for data collection. The app does not knowingly collect personal information from children."
                )
                section(
                    "Changes",
                    "If this policy changes, we will update the “Last updated” date in the app. Continued use after an update means you accept the revised policy."
                )
                section(
                    "Contact",
                    "Questions about this policy: use the support email listed on Grove’s App Store product page."
                )
            }
            .padding(20)
        }
        .background(DeskPaperBackground())
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }

    // LocalizedStringKey so title/body resolve through Localizable.xcstrings (en / zh-Hans).
    private func section(_ title: LocalizedStringKey, _ body: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
                .foregroundStyle(GroveTheme.ink)
            Text(body)
                .font(.body)
                .foregroundStyle(GroveTheme.ink.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
