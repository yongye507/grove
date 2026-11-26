import SwiftUI
import SwiftData

@main
struct GroveApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(for: [
            FocusSession.self,
            FocusTag.self,
            AppSettings.self
        ])
    }
}
