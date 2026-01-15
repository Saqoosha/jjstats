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

        for (index, commit) in commits.enumerated() {
            let isFirst = index == 0

            // 1. Find all columns expecting this commit
            let expectingColumns = activeColumns.filter { $0.value == commit.id }.map { $0.key }.sorted()

            // 2. Determine which column this commit will be placed in
            let column: Int
            if let firstExpecting = expectingColumns.first {
                column = firstExpecting
            } else {
                // New branch - find a free column
                column = findFreeColumn(activeColumns, preferring: 0)
            }
            maxColumn = max(maxColumn, column)

            // 3. Build lines for this row
            var lines: [GraphLine] = []

            // Continuation lines for active columns that are NOT expecting this commit
            for (col, expectedId) in activeColumns {
                if expectedId != commit.id {
                    lines.append(GraphLine(fromColumn: col, toColumn: col, type: .vertical))
                }
            }

            // Lines from other columns expecting this commit (merge lines coming down)
            for col in expectingColumns where col != column {
                lines.append(GraphLine(fromColumn: col, toColumn: column, type: .mergeFrom))
                // Release this column since it merged
                activeColumns.removeValue(forKey: col)
            }

            // Release the column we're using (will be reassigned to parent if exists)
            activeColumns.removeValue(forKey: column)

            // 4. Assign columns for this commit's parents
            for (parentIndex, parentId) in commit.parentIds.enumerated() {
                if parentIndex == 0 {
                    // First parent continues in same column
                    activeColumns[column] = parentId
                } else {
                    // Additional parents (merge sources) get new columns
                    // Use branchTo: line goes FROM this node TO the new column (downward)
                    let newCol = findFreeColumn(activeColumns, preferring: column + 1)
                    activeColumns[newCol] = parentId
                    lines.append(GraphLine(fromColumn: column, toColumn: newCol, type: .branchTo))
                    maxColumn = max(maxColumn, newCol)
                }
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

            // hasChildren: true if any column was expecting this commit (meaning a child references it)
            let hasChildren = !expectingColumns.isEmpty

            rows.append(GraphRow(
                commitId: commit.id,
                column: column,
                lines: lines,
                nodeType: nodeType,
                hasChildren: hasChildren,
                hasParents: !commit.parentIds.isEmpty
            ))
        }

        return GraphLayoutResult(rows: rows, maxColumn: maxColumn)
    }

    /// Find the lowest free column number
    private static func findFreeColumn(_ activeColumns: [Int: String], preferring preferred: Int) -> Int {
        // First try the preferred column
        if activeColumns[preferred] == nil {
            return preferred
        }
        // Then try columns starting from 0
        var col = 0
        while activeColumns[col] != nil {
            col += 1
        }
        return col
    }
}
