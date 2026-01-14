import SwiftUI

struct ContentView: View {
    @State private var repository: JJRepository?
    @State private var showingFolderPicker = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        Group {
            if let repository = repository {
                RepositoryView(repository: repository)
            } else {
                WelcomeView(showingFolderPicker: $showingFolderPicker)
            }
        }
        .fileImporter(
            isPresented: $showingFolderPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    openRepository(at: url.path)
                }
            case .failure(let error):
                print("Error selecting folder: \(error)")
            }
        }
        .onOpenURL { url in
            openRepository(at: url.path)
        }
    }

    private func openRepository(at path: String) {
        // Check if .jj directory exists
        let jjPath = (path as NSString).appendingPathComponent(".jj")
        guard FileManager.default.fileExists(atPath: jjPath) else {
            print("Not a jj repository: \(path)")
            return
        }

        let repo = JJRepository(path: path)
        repository = repo

        Task {
            await repo.start()
        }
    }
}

struct WelcomeView: View {
    @Binding var showingFolderPicker: Bool

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
                showingFolderPicker = true
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
