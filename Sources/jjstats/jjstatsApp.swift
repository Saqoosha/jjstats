import SwiftUI

extension Notification.Name {
    static let openRepository = Notification.Name("openRepository")
}

@main
struct JJStatsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.automatic)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open Repository...") {
                    NotificationCenter.default.post(name: .openRepository, object: nil)
                }
                .keyboardShortcut("o", modifiers: .command)
            }
        }
    }
}
