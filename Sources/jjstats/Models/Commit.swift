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
}
