import SwiftUI
import AppKit

struct ContentView: View {
    @State private var repository: JJRepository?
    @AppStorage("lastRepositoryPath") private var lastRepositoryPath: String?
    @State private var windowRef: NSWindow?
    private static var isPickerOpen = false

    var body: some View {
        Group {
            if let repository = repository {
                RepositoryView(repository: repository, onOpenNew: openFolderPicker)
            } else {
                WelcomeView(onOpen: openFolderPicker, onDrop: { url in
                    openRepository(at: url.path)
                })
            }
        }
        .background(WindowAccessor(windowRef: $windowRef))
        .onOpenURL { url in
            openRepository(at: url.path)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openRepository)) { _ in
            // Only respond if this window is visible
            guard windowRef?.isVisible == true else { return }
            openFolderPicker()
        }
        .onAppear {
            // Delay to allow .openRepository notification to arrive first
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if repository == nil, let path = lastRepositoryPath {
                    openRepository(at: path)
                }
            }
        }
    }

    private func openFolderPicker() {
        // Prevent duplicate pickers
        guard !Self.isPickerOpen else { return }
        Self.isPickerOpen = true
        defer { Self.isPickerOpen = false }

        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.treatsFilePackagesAsDirectories = false
        panel.showsHiddenFiles = false
        panel.message = "Select a jj repository folder"
        panel.prompt = "Select"

        if panel.runModal() == .OK, let url = panel.url {
            openRepository(at: url.path)
        }
    }

    private func openRepository(at path: String) {
        // Check if .jj directory exists
        let jjPath = (path as NSString).appendingPathComponent(".jj")
        guard FileManager.default.fileExists(atPath: jjPath) else {
            print("Not a jj repository: \(path)")
            // Show alert
            let alert = NSAlert()
            alert.messageText = "Not a jj repository"
            alert.informativeText = "The selected folder does not contain a .jj directory."
            alert.alertStyle = .warning
            alert.runModal()
            return
        }

        let repo = JJRepository(path: path)
        repository = repo
        lastRepositoryPath = path

        Task {
            await repo.start()
        }
    }
}

// MARK: - Welcome View

struct WelcomeView: View {
    let onOpen: () -> Void
    let onDrop: (URL) -> Void
    @State private var isTargeted = false

    var body: some View {
        ZStack {
            // Subtle gradient background
            LinearGradient(
                colors: [
                    Color(nsColor: .windowBackgroundColor),
                    Color(nsColor: .windowBackgroundColor).opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                // App icon area
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.1))
                        .frame(width: 100, height: 100)

                    Image(systemName: "arrow.triangle.branch")
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(Color.accentColor)
                }

                VStack(spacing: 8) {
                    Text("jjstats")
                        .font(.largeTitle)
                        .fontWeight(.semibold)

                    Text("Visualize your Jujutsu repository history")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                Button {
                    onOpen()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "folder")
                        Text("Open Repository")
                    }
                    .frame(minWidth: 160)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                // Hint text
                Text("Or drag a folder here")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .overlay {
            if isTargeted {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.accentColor, lineWidth: 3)
                    .padding(8)
            }
        }
        .dropDestination(for: URL.self) { urls, _ in
            guard let url = urls.first else { return false }
            onDrop(url)
            return true
        } isTargeted: { targeted in
            isTargeted = targeted
        }
    }
}

// MARK: - Repository View

struct RepositoryView: View {
    @Bindable var repository: JJRepository
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    let onOpenNew: () -> Void

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            CommitListView(repository: repository)
                .navigationSplitViewColumnWidth(min: 220, ideal: 300, max: 420)
        } detail: {
            if let commit = repository.selectedCommit {
                CommitDetailView(
                    commit: commit,
                    changes: repository.selectedCommitChanges,
                    repository: repository
                )
            } else {
                EmptyDetailView()
            }
        }
        .navigationTitle(repositoryName)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    onOpenNew()
                } label: {
                    Label("Open", systemImage: "folder")
                }
                .help("Open another repository")
            }

            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task {
                        await repository.refresh()
                    }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(repository.isLoading)
                .help("Refresh repository")
            }
        }
        .overlay {
            if repository.isLoading && repository.commits.isEmpty {
                LoadingView()
            }
        }
    }

    private var repositoryName: String {
        (repository.path as NSString).lastPathComponent
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)

            Text("Loading repository...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Window Accessor

struct WindowAccessor: NSViewRepresentable {
    private static let frameKey = "MainWindowFrame"
    @Binding var windowRef: NSWindow?

    func makeNSView(context: Context) -> NSView {
        let view = WindowFrameManager(windowRefBinding: $windowRef)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    static func savedFrame() -> NSRect? {
        let defaults = UserDefaults.standard
        let x = defaults.double(forKey: "\(frameKey).x")
        let y = defaults.double(forKey: "\(frameKey).y")
        let width = defaults.double(forKey: "\(frameKey).width")
        let height = defaults.double(forKey: "\(frameKey).height")
        guard width > 0 && height > 0 else { return nil }
        return NSRect(x: x, y: y, width: width, height: height)
    }

    static func saveFrame(_ frame: NSRect) {
        let defaults = UserDefaults.standard
        defaults.set(frame.origin.x, forKey: "\(frameKey).x")
        defaults.set(frame.origin.y, forKey: "\(frameKey).y")
        defaults.set(frame.size.width, forKey: "\(frameKey).width")
        defaults.set(frame.size.height, forKey: "\(frameKey).height")
    }
}

@MainActor
private class WindowFrameManager: NSView, NSWindowDelegate {
    private var didConfigure = false
    private var windowRefBinding: Binding<NSWindow?>?

    convenience init(windowRefBinding: Binding<NSWindow?>) {
        self.init(frame: .zero)
        self.windowRefBinding = windowRefBinding
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let window, !didConfigure else { return }
        didConfigure = true

        // Store window reference
        windowRefBinding?.wrappedValue = window

        // Restore saved frame
        if let savedFrame = WindowAccessor.savedFrame() {
            window.setFrame(savedFrame, display: true)
        }

        // Set delegate to save frame on changes
        window.delegate = self
    }

    nonisolated func windowDidResize(_ notification: Notification) {
        saveFrame(from: notification)
    }

    nonisolated func windowDidMove(_ notification: Notification) {
        saveFrame(from: notification)
    }

    nonisolated func windowWillClose(_ notification: Notification) {
        // Clear last repository path when window is closed
        Task { @MainActor in
            UserDefaults.standard.removeObject(forKey: "lastRepositoryPath")
        }
    }

    private nonisolated func saveFrame(from notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        let size = window.frame.size
        let origin = window.frame.origin
        Task { @MainActor in
            WindowAccessor.saveFrame(NSRect(origin: origin, size: size))
        }
    }
}
