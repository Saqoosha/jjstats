import Foundation

struct Commit: Identifiable, Equatable {
    let id: String  // commit_id
    let changeId: String
    let description: String
    let author: String
    let timestamp: Date
    let isWorkingCopy: Bool

    var shortChangeId: String {
        String(changeId.prefix(8))
    }

    var shortDescription: String {
        description.isEmpty ? "(no description)" : description
    }
}
