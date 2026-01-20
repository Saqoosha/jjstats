import Foundation

struct Commit: Identifiable, Equatable {
    let id: String  // commit_id
    let changeId: String
    let description: String
    let authorName: String
    let authorEmail: String
    let timestamp: Date
    let isWorkingCopy: Bool
    let bookmarks: [String]  // e.g., ["main", "main@origin"]
    let tags: [String]  // git tags, e.g., ["v1.0.0"]
    let signatureStatus: String?  // nil = unsigned, "good" = valid, "bad" = invalid
    let parentIds: [String]  // parent commit IDs (empty = root, 1 = normal, 2+ = merge)
    let isEmpty: Bool  // true if commit has no file changes

    var shortChangeId: String {
        String(changeId.prefix(8))
    }

    var shortDescription: String {
        description.isEmpty ? "(no description)" : description
    }

    var isSigned: Bool {
        signatureStatus != nil
    }

    var hasValidSignature: Bool {
        signatureStatus == "good"
    }

    // Local bookmarks (without @remote suffix)
    var localBookmarks: [String] {
        bookmarks.filter { !$0.contains("@") }
    }

    // Remote bookmarks (with @remote suffix)
    var remoteBookmarks: [String] {
        bookmarks.filter { $0.contains("@") }
    }

    // Check if a local bookmark is synced with remote
    func isBookmarkSynced(_ bookmark: String) -> Bool {
        guard localBookmarks.contains(bookmark) else { return false }
        return remoteBookmarks.contains { $0.hasPrefix("\(bookmark)@") }
    }

    var isRootCommit: Bool {
        parentIds.isEmpty
    }

    var isMergeCommit: Bool {
        parentIds.count > 1
    }


    /// Sort commits in topological order (children before parents)
    /// Uses Kahn's algorithm with timestamp as tiebreaker
    static func topologicalSort(_ commits: [Commit]) -> [Commit] {
        guard commits.count > 1 else { return commits }

        // Build lookup map
        let commitMap = Dictionary(uniqueKeysWithValues: commits.map { ($0.id, $0) })
        let commitIds = Set(commits.map { $0.id })

        // Calculate child count for each commit (only counting commits in our list)
        var childCount: [String: Int] = [:]
        for commit in commits {
            childCount[commit.id] = 0
        }
        for commit in commits {
            for parentId in commit.parentIds where commitIds.contains(parentId) {
                childCount[parentId, default: 0] += 1
            }
        }

        // Start with commits that have no children (heads)
        // Sort by timestamp (newest first) as tiebreaker
        var queue = commits
            .filter { childCount[$0.id] == 0 }
            .sorted { $0.timestamp > $1.timestamp }

        var result: [Commit] = []
        var visited = Set<String>()

        while !queue.isEmpty {
            let commit = queue.removeFirst()

            guard !visited.contains(commit.id) else { continue }
            visited.insert(commit.id)
            result.append(commit)

            // Process parents
            var parentsToAdd: [Commit] = []
            for parentId in commit.parentIds {
                guard let parent = commitMap[parentId],
                      !visited.contains(parentId) else { continue }

                childCount[parentId, default: 0] -= 1
                if childCount[parentId] == 0 {
                    parentsToAdd.append(parent)
                }
            }

            // Sort parents by timestamp (newest first) and prepend to queue
            parentsToAdd.sort { $0.timestamp > $1.timestamp }
            queue.insert(contentsOf: parentsToAdd, at: 0)
        }

        return result
    }
}
