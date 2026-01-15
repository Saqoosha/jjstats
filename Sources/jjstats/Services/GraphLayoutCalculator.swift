import Foundation

/// Calculates graph layout from a list of commits
struct GraphLayoutCalculator {

    /// Calculate graph layout from commits
    /// - Parameter commits: Commits in newest-first order (top to bottom)
    /// - Returns: Layout result with rows and max column
    static func calculate(commits: [Commit]) -> GraphLayoutResult {
        var rows: [GraphRow] = []
        var maxColumn = 0

        // Track active columns: column index -> expected commit ID
        var activeColumns: [Int: String] = [:]

        for commit in commits {
            // 1. Find which column this commit should be placed in
            let column = findColumn(for: commit.id, in: &activeColumns)
            maxColumn = max(maxColumn, column)

            // 2. Build lines for this row
            var lines: [GraphLine] = []

            // Continuation lines for all active columns except this commit's column
            for (col, _) in activeColumns where col != column {
                lines.append(GraphLine(fromColumn: col, toColumn: col, type: .vertical))
            }

            // 3. Assign columns for this commit's parents
            for (index, parentId) in commit.parentIds.enumerated() {
                if index == 0 {
                    // First parent continues in same column
                    activeColumns[column] = parentId
                } else {
                    // Additional parents (merge sources) get new columns
                    let newCol = findFreeColumn(activeColumns, preferring: column + 1)
                    activeColumns[newCol] = parentId
                    lines.append(GraphLine(fromColumn: newCol, toColumn: column, type: .mergeFrom))
                    maxColumn = max(maxColumn, newCol)
                }
            }

            // 4. If this commit has no parents (root), release the column
            if commit.parentIds.isEmpty {
                activeColumns.removeValue(forKey: column)
            }

            // 5. Determine node type
            let nodeType: GraphNodeType
            if commit.isWorkingCopy {
                nodeType = .workingCopy
            } else if commit.isMergeCommit {
                nodeType = .merge
            } else {
                nodeType = .normal
            }

            rows.append(GraphRow(
                commitId: commit.id,
                column: column,
                lines: lines,
                nodeType: nodeType
            ))
        }

        return GraphLayoutResult(rows: rows, maxColumn: maxColumn)
    }

    /// Find the column for a commit ID, or assign a new one
    private static func findColumn(for commitId: String, in activeColumns: inout [Int: String]) -> Int {
        // Check if this commit is already expected in a column
        for (col, expectedId) in activeColumns {
            if expectedId == commitId {
                return col
            }
        }
        // Assign a new column
        return findFreeColumn(activeColumns, preferring: 0)
    }

    /// Find the lowest free column number
    private static func findFreeColumn(_ activeColumns: [Int: String], preferring preferred: Int) -> Int {
        var col = preferred
        while activeColumns[col] != nil {
            col += 1
        }
        // Also check lower columns if preferred wasn't available
        if col != preferred {
            for i in 0..<preferred {
                if activeColumns[i] == nil {
                    return i
                }
            }
        }
        return col
    }
}
