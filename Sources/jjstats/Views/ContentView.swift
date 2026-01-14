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

struct WelcomeView: View {
    let onOpen: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("jjstats")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Open a jj repository to view its history")
                .font(.body)
                .foregroundStyle(.secondary)

            Button("Open Repository...") {
                onOpen()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
}

struct RepositoryView: View {
    @Bindable var repository: JJRepository
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    let onOpenNew: () -> Void

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            CommitListView(repository: repository)
                .navigationSplitViewColumnWidth(min: 200, ideal: 280, max: 400)
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
            }
        }
        .overlay {
            if repository.isLoading && repository.commits.isEmpty {
                ProgressView()
                    .controlSize(.large)
            }
        }
    }

    private var repositoryName: String {
        (repository.path as NSString).lastPathComponent
    }
}
