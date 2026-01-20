import Foundation

@Observable
@MainActor
final class RecentRepositoriesManager {
    static let shared = RecentRepositoriesManager()

    private static let storageKey = "recentRepositories"
    private static let maxCount = 10

    private(set) var repositories: [RecentRepository] = []

    private init() {
        loadRepositories()
    }

    func addRepository(path: String) {
        // Remove if already exists (will be re-added at top)
        repositories.removeAll { $0.path == path }

        // Add to the beginning
        let name = (path as NSString).lastPathComponent
        repositories.insert(RecentRepository(path: path, name: name), at: 0)

        // Keep only the most recent
        if repositories.count > Self.maxCount {
            repositories = Array(repositories.prefix(Self.maxCount))
        }

        saveRepositories()
    }

    func removeRepository(path: String) {
        repositories.removeAll { $0.path == path }
        saveRepositories()
    }

    func clearAll() {
        repositories.removeAll()
        saveRepositories()
    }

    func filterInvalidPaths() {
        let fileManager = FileManager.default
        repositories = repositories.filter { repo in
            let jjPath = (repo.path as NSString).appendingPathComponent(".jj")
            return fileManager.fileExists(atPath: jjPath)
        }
        saveRepositories()
    }

    private func loadRepositories() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let decoded = try? JSONDecoder().decode([RecentRepository].self, from: data) else {
            return
        }
        repositories = decoded
        // Filter out invalid paths on load
        filterInvalidPaths()
    }

    private func saveRepositories() {
        guard let data = try? JSONEncoder().encode(repositories) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }
}

struct RecentRepository: Codable, Identifiable, Equatable {
    let path: String
    let name: String

    var id: String { path }
}
