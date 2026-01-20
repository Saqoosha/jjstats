import SwiftUI
import AppKit

extension Notification.Name {
    static let openRepository = Notification.Name("openRepository")
    static let openRepositoryAtPath = Notification.Name("openRepositoryAtPath")
}

@main
struct JJStatsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
                .withOpenWindowCapture(appDelegate: appDelegate)
        }
        .defaultSize(width: 900, height: 600)
        .windowStyle(.automatic)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open Repository...") {
                    appDelegate.openRepository()
                }
                .keyboardShortcut("o", modifiers: .command)

                RecentRepositoriesMenu { path in
                    appDelegate.openRepository(at: path)
                }
            }
        }
    }
}

// Helper view to capture openWindow action
struct OpenWindowCaptureModifier: ViewModifier {
    let appDelegate: AppDelegate
    @Environment(\.openWindow) private var openWindow

    func body(content: Content) -> some View {
        content
            .onAppear {
                appDelegate.openWindowAction = {
                    openWindow(id: "main")
                }
            }
    }
}

extension View {
    func withOpenWindowCapture(appDelegate: AppDelegate) -> some View {
        modifier(OpenWindowCaptureModifier(appDelegate: appDelegate))
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var openWindowAction: (() -> Void)?
    nonisolated(unsafe) static var isTerminating = false

    func applicationWillTerminate(_ notification: Notification) {
        Self.isTerminating = true
    }

    @MainActor func openRepository() {
        showWindowAndPost(notification: .openRepository, userInfo: nil)
    }

    @MainActor func openRepository(at path: String) {
        showWindowAndPost(notification: .openRepositoryAtPath, userInfo: ["path": path])
    }

    @MainActor private func showWindowAndPost(notification: Notification.Name, userInfo: [String: Any]?) {
        // First try to find and show existing window
        let contentWindows = NSApp.windows.filter { window in
            // Filter out menu bar windows, panels, etc.
            window.contentView != nil &&
            window.canBecomeMain &&
            !window.className.contains("NSStatusBarWindow") &&
            !window.className.contains("NSMenuWindowManagerWindow")
        }

        if let window = contentWindows.first {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NotificationCenter.default.post(name: notification, object: nil, userInfo: userInfo)
            }
        } else if let openWindow = openWindowAction {
            openWindow()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                NotificationCenter.default.post(name: notification, object: nil, userInfo: userInfo)
            }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            openRepository()
        }
        return true
    }
}
