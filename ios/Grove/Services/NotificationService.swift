import Foundation
import UserNotifications

enum NotificationService {
    static let sessionEndId = "grove.session.end"

    static func requestPermissionIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    static func scheduleSessionEnd(at date: Date, durationMinutes: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [sessionEndId])

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Fully grown")
        content.body = String(
            localized: "Your \(durationMinutes)-minute tree finished growing — see it in Grove."
        )
        // Default alert sound; follows system notification volume / mute settings.
        content.sound = .default

        let interval = max(date.timeIntervalSinceNow, 1)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: sessionEndId, content: content, trigger: trigger)
        center.add(request)
    }

    static func cancelSessionEnd() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [sessionEndId])
    }
}
