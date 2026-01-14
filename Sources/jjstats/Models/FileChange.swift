import Foundation

enum FileChangeStatus: String {
    case modified = "M"
    case added = "A"
    case deleted = "D"
    case renamed = "R"
    case copied = "C"

    var description: String {
        switch self {
        case .modified: return "Modified"
        case .added: return "Added"
        case .deleted: return "Deleted"
        case .renamed: return "Renamed"
        case .copied: return "Copied"
        }
    }
}

struct FileChange: Identifiable, Equatable {
    let id: String
    let path: String
    let status: FileChangeStatus

    init(path: String, status: FileChangeStatus) {
        self.id = "\(status.rawValue):\(path)"
        self.path = path
        self.status = status
    }
}
