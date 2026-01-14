import Foundation

enum DiffLineType: Equatable {
    case context    // unchanged line (space prefix)
    case addition   // added line (+ prefix)
    case deletion   // deleted line (- prefix)
}

struct DiffLine: Identifiable, Equatable {
    let id: UUID
    let type: DiffLineType
    let content: String
    let oldLineNumber: Int?
    let newLineNumber: Int?

    init(type: DiffLineType, content: String, oldLineNumber: Int?, newLineNumber: Int?) {
        self.id = UUID()
        self.type = type
        self.content = content
        self.oldLineNumber = oldLineNumber
        self.newLineNumber = newLineNumber
    }
}

struct DiffHunk: Identifiable, Equatable {
    let id: UUID
    let header: String
    let oldStart: Int
    let oldCount: Int
    let newStart: Int
    let newCount: Int
    let lines: [DiffLine]

    init(header: String, oldStart: Int, oldCount: Int, newStart: Int, newCount: Int, lines: [DiffLine]) {
        self.id = UUID()
        self.header = header
        self.oldStart = oldStart
        self.oldCount = oldCount
        self.newStart = newStart
        self.newCount = newCount
        self.lines = lines
    }
}

struct DiffStats: Equatable {
    let additions: Int
    let deletions: Int
}

struct FileDiff: Identifiable, Equatable {
    let id: String
    let path: String
    let hunks: [DiffHunk]
    let stats: DiffStats

    init(path: String, hunks: [DiffHunk], stats: DiffStats) {
        self.id = path
        self.path = path
        self.hunks = hunks
        self.stats = stats
    }
}
