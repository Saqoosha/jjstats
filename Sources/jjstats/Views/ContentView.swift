import SwiftUI
import AppKit

struct ContentView: View {
    @State private var repository: JJRepository?
    @AppStorage("lastRepositoryPath") private var lastRepositoryPath: String?

    var body: some View {
        Group {
            if let repository = repository {
                RepositoryView(repository: repository, onOpenNew: openFolderPicker)
            } else {
                WelcomeView(onOpen: openFolderPicker)
            }
        }
        .onOpenURL { url in
            openRepository(at: url.path)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openRepository)) { _ in
            openFolderPicker()
        }
        .onAppear {
            if let path = lastRepositoryPath {
                openRepository(at: path)
            }
        }
    }

    private func openFolderPicker() {
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
                    changes: repository.selectedCommitChanges
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
