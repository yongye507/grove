import Foundation
import SwiftData

@Model
final class AppSettings {
    @Attribute(.unique) var id: String
    var graceSec: Int
    var defaultDurationSec: Int
    var soundOn: Bool
    var lifetimeUnlocked: Bool

    init(
        id: String = "default",
        graceSec: Int = 5,
        defaultDurationSec: Int = 25 * 60,
        soundOn: Bool = false,
        lifetimeUnlocked: Bool = false
    ) {
        self.id = id
        self.graceSec = graceSec
        self.defaultDurationSec = defaultDurationSec
        self.soundOn = soundOn
        self.lifetimeUnlocked = lifetimeUnlocked
    }
}
