import SwiftUI

struct RecentRepositoriesMenu: View {
    let onSelect: (String) -> Void
    @State private var recentManager = RecentRepositoriesManager.shared

    var body: some View {
        Menu("Open Recent") {
            if recentManager.repositories.isEmpty {
                Text("No Recent Repositories")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(recentManager.repositories) { repo in
                    Button(abbreviatePath(repo.path)) {
                        onSelect(repo.path)
                    }
                }

                Divider()

                Button("Clear Menu") {
                    recentManager.clearAll()
                }
            }
        }
    }

    private func abbreviatePath(_ path: String) -> String {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        if path.hasPrefix(homeDir) {
            return "~" + path.dropFirst(homeDir.count)
        }
        return path
    }
}

struct RecentRepositoriesToolbarMenu: View {
    let onSelect: (String) -> Void
    let onOpenOther: () -> Void
    @State private var recentManager = RecentRepositoriesManager.shared

    var body: some View {
        Menu {
            if !recentManager.repositories.isEmpty {
                ForEach(recentManager.repositories) { repo in
                    Button {
                        onSelect(repo.path)
                    } label: {
                        Label {
                            Text(abbreviatePath(repo.path))
                        } icon: {
                            Image(systemName: "folder")
                        }
                    }
                }

                Divider()
            }

            Button {
                onOpenOther()
            } label: {
                Label("Open Other...", systemImage: "folder.badge.plus")
            }
        } label: {
            Label("Open", systemImage: "folder")
        }
        .menuIndicator(.visible)
        .help("Open repository")
    }

    private func abbreviatePath(_ path: String) -> String {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        if path.hasPrefix(homeDir) {
            return "~" + path.dropFirst(homeDir.count)
        }
        return path
    }
}
