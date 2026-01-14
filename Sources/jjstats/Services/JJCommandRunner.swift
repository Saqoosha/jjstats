import Foundation

enum JJError: Error, LocalizedError {
    case commandFailed(String)
    case notARepository
    case parseError(String)

    var errorDescription: String? {
        switch self {
        case .commandFailed(let message):
            return "jj command failed: \(message)"
        case .notARepository:
            return "Not a jj repository"
        case .parseError(let message):
            return "Parse error: \(message)"
        }
    }
}

actor JJCommandRunner {
    private let repoPath: String
    private let jjPath: String

    // Template for parsing commit info
    // Fields separated by \x00, records separated by \x1e
    private static let logTemplate = """
        commit_id ++ "\\x00" ++ change_id ++ "\\x00" ++
        description.first_line() ++ "\\x00" ++
        author.email() ++ "\\x00" ++
        committer.timestamp().utc().format("%Y-%m-%dT%H:%M:%SZ") ++ "\\x00" ++
        if(current_working_copy, "true", "false") ++ "\\x00" ++
        local_bookmarks ++ " " ++ remote_bookmarks ++ "\\x00" ++
        tags ++ "\\x1e"
        """

    init(repoPath: String, jjPath: String = "/opt/homebrew/bin/jj") {
        self.repoPath = repoPath
        self.jjPath = jjPath
    }

    func fetchLog(limit: Int = 50) async throws -> [Commit] {
        let output = try await runCommand([
            "log",
            "-r", "::",
            "--no-graph",
            "-n", String(limit),
            "-T", Self.logTemplate
        ])

        return try parseLogOutput(output)
    }

    func fetchDiff(revision: String = "@") async throws -> [FileChange] {
        let output = try await runCommand([
            "diff",
            "-r", revision,
            "--summary"
        ])

        return parseDiffOutput(output)
    }

    func fetchStatus() async throws -> [FileChange] {
        let output = try await runCommand(["status"])
        return parseStatusOutput(output)
    }

    func fetchFileDiff(revision: String, filePath: String) async throws -> FileDiff {
        let output = try await runCommand([
            "diff",
            "-r", revision,
            "--git",
            filePath
        ])
        return parseGitDiff(output, filePath: filePath)
    }

    private func runCommand(_ arguments: [String]) async throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: jjPath)
        process.currentDirectoryURL = URL(fileURLWithPath: repoPath)
        process.arguments = ["-R", repoPath] + arguments
        process.environment = ProcessInfo.processInfo.environment

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        try process.run()
        process.waitUntilExit()

        let outputData = stdout.fileHandleForReading.readDataToEndOfFile()
        let errorData = stderr.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: outputData, encoding: .utf8) ?? ""
        let errorOutput = String(data: errorData, encoding: .utf8) ?? ""

        if process.terminationStatus != 0 {
            if errorOutput.contains("no jj repo") {
                throw JJError.notARepository
            }
            throw JJError.commandFailed(errorOutput)
        }

        return output
    }

    private func parseLogOutput(_ output: String) throws -> [Commit] {
        let records = output.split(separator: "\u{1e}", omittingEmptySubsequences: true)
        var commits: [Commit] = []

        let dateFormatter = ISO8601DateFormatter()

        for record in records {
            let fields = record.split(separator: "\u{00}", omittingEmptySubsequences: false)
            guard fields.count >= 8 else { continue }

            let commitId = String(fields[0])
            let changeId = String(fields[1])
            let description = String(fields[2])
            let author = String(fields[3])
            let timestampStr = String(fields[4]).trimmingCharacters(in: .whitespacesAndNewlines)
            let isWorkingCopy = String(fields[5]).trimmingCharacters(in: .whitespacesAndNewlines) == "true"
            let bookmarksStr = String(fields[6]).trimmingCharacters(in: .whitespacesAndNewlines)
            let tagsStr = String(fields[7]).trimmingCharacters(in: .whitespacesAndNewlines)

            let timestamp = dateFormatter.date(from: timestampStr) ?? Date()

            // Parse bookmarks: "main main@origin" -> ["main", "main@origin"]
            let bookmarks = bookmarksStr.isEmpty ? [] : bookmarksStr.split(separator: " ").map(String.init)

            // Parse tags: "v1.0.0 v1.0.1" -> ["v1.0.0", "v1.0.1"]
            let tags = tagsStr.isEmpty ? [] : tagsStr.split(separator: " ").map(String.init)

            commits.append(Commit(
                id: commitId,
                changeId: changeId,
                description: description,
                author: author,
                timestamp: timestamp,
                isWorkingCopy: isWorkingCopy,
                bookmarks: bookmarks,
                tags: tags
            ))
        }

        return commits
    }

    private func parseDiffOutput(_ output: String) -> [FileChange] {
        var changes: [FileChange] = []

        for line in output.split(separator: "\n", omittingEmptySubsequences: true) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.count >= 2 else { continue }

            let statusChar = String(trimmed.prefix(1))
            let path = String(trimmed.dropFirst(2))

            if let status = FileChangeStatus(rawValue: statusChar) {
                changes.append(FileChange(path: path, status: status))
            }
        }

        return changes
    }

    private func parseStatusOutput(_ output: String) -> [FileChange] {
        // jj status output format:
        // Working copy changes:
        // M path/to/file
        // A new/file
        var changes: [FileChange] = []
        var inWorkingCopySection = false

        for line in output.split(separator: "\n", omittingEmptySubsequences: false) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("Working copy changes:") {
                inWorkingCopySection = true
                continue
            }

            if inWorkingCopySection && trimmed.isEmpty {
                break
            }

            if inWorkingCopySection && trimmed.count >= 2 {
                let statusChar = String(trimmed.prefix(1))
                let path = String(trimmed.dropFirst(2))

                if let status = FileChangeStatus(rawValue: statusChar) {
                    changes.append(FileChange(path: path, status: status))
                }
            }
        }

        return changes
    }

    private func parseGitDiff(_ output: String, filePath: String) -> FileDiff {
        var hunks: [DiffHunk] = []
        var additions = 0
        var deletions = 0

        let lines = output.components(separatedBy: "\n")
        var currentHunkLines: [DiffLine] = []
        var currentHunkHeader: String?
        var oldStart = 0, oldCount = 0, newStart = 0, newCount = 0
        var oldLineNum = 0
        var newLineNum = 0

        let hunkHeaderPattern = try! NSRegularExpression(
            pattern: #"^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@"#
        )

        for line in lines {
            // Hunk header: @@ -1,4 +1,5 @@
            if line.hasPrefix("@@") {
                // Save previous hunk
                if let header = currentHunkHeader, !currentHunkLines.isEmpty {
                    hunks.append(DiffHunk(
                        header: header,
                        oldStart: oldStart,
                        oldCount: oldCount,
                        newStart: newStart,
                        newCount: newCount,
                        lines: currentHunkLines
                    ))
                }

                // Start new hunk
                currentHunkHeader = line
                currentHunkLines = []

                // Parse: @@ -1,4 +1,5 @@
                let range = NSRange(line.startIndex..., in: line)
                if let match = hunkHeaderPattern.firstMatch(in: line, range: range) {
                    oldStart = Int(line[Range(match.range(at: 1), in: line)!])!
                    oldCount = match.range(at: 2).location != NSNotFound
                        ? Int(line[Range(match.range(at: 2), in: line)!]) ?? 1
                        : 1
                    newStart = Int(line[Range(match.range(at: 3), in: line)!])!
                    newCount = match.range(at: 4).location != NSNotFound
                        ? Int(line[Range(match.range(at: 4), in: line)!]) ?? 1
                        : 1
                }
                oldLineNum = oldStart
                newLineNum = newStart
                continue
            }

            guard currentHunkHeader != nil else { continue }

            // Skip file headers
            if line.hasPrefix("diff --git") ||
               line.hasPrefix("index ") ||
               line.hasPrefix("--- ") ||
               line.hasPrefix("+++ ") ||
               line.hasPrefix("new file mode") ||
               line.hasPrefix("deleted file mode") {
                continue
            }

            // Parse diff lines
            if line.hasPrefix("+") {
                let content = String(line.dropFirst())
                currentHunkLines.append(DiffLine(
                    type: .addition,
                    content: content,
                    oldLineNumber: nil,
                    newLineNumber: newLineNum
                ))
                newLineNum += 1
                additions += 1
            } else if line.hasPrefix("-") {
                let content = String(line.dropFirst())
                currentHunkLines.append(DiffLine(
                    type: .deletion,
                    content: content,
                    oldLineNumber: oldLineNum,
                    newLineNumber: nil
                ))
                oldLineNum += 1
                deletions += 1
            } else if line.hasPrefix(" ") || (currentHunkHeader != nil && line.isEmpty) {
                let content = line.isEmpty ? "" : String(line.dropFirst())
                currentHunkLines.append(DiffLine(
                    type: .context,
                    content: content,
                    oldLineNumber: oldLineNum,
                    newLineNumber: newLineNum
                ))
                oldLineNum += 1
                newLineNum += 1
            }
        }

        // Add last hunk
        if let header = currentHunkHeader, !currentHunkLines.isEmpty {
            hunks.append(DiffHunk(
                header: header,
                oldStart: oldStart,
                oldCount: oldCount,
                newStart: newStart,
                newCount: newCount,
                lines: currentHunkLines
            ))
        }

        return FileDiff(
            path: filePath,
            hunks: hunks,
            stats: DiffStats(additions: additions, deletions: deletions)
        )
    }
}
