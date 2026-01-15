import Foundation

/// Type of graph node
enum GraphNodeType {
    case normal
    case merge       // Multiple parents
    case workingCopy
}

/// Type of graph line
enum GraphLineType {
    case vertical    // Straight vertical line (continuation)
    case mergeFrom   // Line from merge source
    case branchTo    // Line to branch target
}

/// A single line segment in the graph
struct GraphLine: Equatable {
    let fromColumn: Int
    let toColumn: Int
    let type: GraphLineType
}

/// Layout information for a single row (one commit) in the graph
struct GraphRow: Equatable {
    let commitId: String
    let column: Int           // Column where this commit's node is placed
    let lines: [GraphLine]    // All lines to draw for this row
    let nodeType: GraphNodeType
}

/// Result of graph layout calculation
struct GraphLayoutResult: Equatable {
    let rows: [GraphRow]
    let maxColumn: Int        // Maximum column index (for width calculation)
}
