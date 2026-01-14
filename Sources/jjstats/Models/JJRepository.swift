import Foundation
import os.log
import SwiftUI

private let logger = Logger(subsystem: "sh.saqoo.jjstats", category: "JJRepository")

@MainActor
@Observable
final class JJRepository {
    private(set) var commits: [Commit] = []
    private(set) var currentChanges: [FileChange] = []
    private(set) var selectedCommitChanges: [FileChange] = []
    private(set) var selectedFileDiff: FileDiff?
    private(set) var isLoading = false
    private(set) var isLoadingFileDiff = false
    private(set) var error: Error?
    var selectedCommit: Commit?
    var selectedFileChange: FileChange?

    let path: String
    private var commandRunner: JJCommandRunner?
    private var fileWatcher: FileWatcher?
    private var isRefreshing = false
    private var lastWorkingCopyId: String?

    var workingCopyCommit: Commit? {
        commits.first { $0.isWorkingCopy }
    }

    init(path: String) {
        self.path = path
    }

    func start() async {
        commandRunner = JJCommandRunner(repoPath: path)

        // Watch only op_heads/heads which changes on real jj operations
        // (jj new, jj commit, jj edit, etc.)
        // Do NOT watch working_copy - it has lock files that change on every jj command
        let jjPath = path as NSString
        let watchPaths = [
            jjPath.appendingPathComponent(".jj/repo/op_heads/heads"),
        ]
        fileWatcher = FileWatcher(paths: watchPaths, debounceInterval: 0.5) { [weak self] in
            Task { @MainActor [weak self] in
                await self?.refresh()
            }
        }
        fileWatcher?.start()

        await refresh()
    }

    func stop() {
        fileWatcher?.stop()
        fileWatcher = nil
        commandRunner = nil
    }

    func refresh() async {
        guard let runner = commandRunner else { return }

        // Skip if already refreshing
        guard !isRefreshing else {
            logger.info(" Skipping refresh - already in progress")
            return
        }

        isRefreshing = true
        isLoading = true
        error = nil

        logger.info(" Starting refresh...")

        do {
            async let fetchedCommits = runner.fetchLog()
            async let fetchedStatus = runner.fetchStatus()

            commits = try await fetchedCommits
            currentChanges = try await fetchedStatus

            let commitCount = commits.count
            let changeCount = currentChanges.count
            logger.info("Loaded \(commitCount) commits, \(changeCount) changes")

            // Check if working copy changed
            let newWorkingCopy = commits.first(where: { $0.isWorkingCopy }) ?? commits.first
            let workingCopyChanged = newWorkingCopy?.id != lastWorkingCopyId
            lastWorkingCopyId = newWorkingCopy?.id

            // Auto-select working copy if:
            // - Nothing selected
            // - Working copy changed (new change created)
            // - Current selection no longer exists
            let currentSelection = selectedCommit
            let selectionStillExists = currentSelection.map { sel in
                commits.contains { $0.id == sel.id }
            } ?? false

            if currentSelection == nil || workingCopyChanged || !selectionStillExists {
                if let workingCopy = newWorkingCopy {
                    selectedCommit = workingCopy
                    selectedCommitChanges = try await runner.fetchDiff(revision: workingCopy.changeId)
                    logger.info(" Auto-selected working copy: \(workingCopy.shortChangeId)")
                }
            } else if let selected = currentSelection {
                // Refresh changes for current selection
                selectedCommitChanges = try await runner.fetchDiff(revision: selected.changeId)
            }
        } catch {
            logger.info(" Error: \(error)")
            self.error = error
        }

        isLoading = false
        isRefreshing = false
    }

    func selectCommit(_ commit: Commit?) async {
        selectedCommit = commit
        selectedFileChange = nil
        selectedFileDiff = nil

        guard let commit = commit, let runner = commandRunner else {
            selectedCommitChanges = []
            return
        }

        do {
            selectedCommitChanges = try await runner.fetchDiff(revision: commit.changeId)
        } catch {
            self.error = error
            selectedCommitChanges = []
        }
    }

    func selectFileChange(_ change: FileChange?) async {
        guard let change = change,
              let commit = selectedCommit,
              let runner = commandRunner else {
            selectedFileChange = nil
            selectedFileDiff = nil
            return
        }

        selectedFileChange = change
        isLoadingFileDiff = true

        do {
            selectedFileDiff = try await runner.fetchFileDiff(
                revision: commit.changeId,
                filePath: change.path
            )
        } catch {
            self.error = error
            selectedFileDiff = nil
        }

        isLoadingFileDiff = false
    }
}
