import AudioToolbox
import UIKit

/// End-of-session feedback.
/// Audio uses system sounds that follow the Ring / Silent switch.
enum CompletionFeedback {
    private static let successSound: SystemSoundID = 1005

    static func playSuccess() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        AudioServicesPlaySystemSound(successSound)
    }

    static func playWilt() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        // Soft "wrong" tick; silent switch suppresses audio.
        AudioServicesPlaySystemSound(1053)
    }
}
