import Foundation
import SwiftUI

@MainActor
@Observable
final class JJRepository {
    private(set) var commits: [Commit] = []
    private(set) var currentChanges: [FileChange] = []
    private(set) var selectedCommitChanges: [FileChange] = []
    private(set) var isLoading = false
    private(set) var error: Error?
    var selectedCommit: Commit?

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

        // Start file watcher on .jj directory
        let jjPath = (path as NSString).appendingPathComponent(".jj")
        fileWatcher = FileWatcher(path: jjPath, debounceInterval: 2.0) { [weak self] in
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
            print("[JJRepository] Skipping refresh - already in progress")
            return
        }

        isRefreshing = true
        isLoading = true
        error = nil

        print("[JJRepository] Starting refresh...")

        do {
            async let fetchedCommits = runner.fetchLog()
            async let fetchedStatus = runner.fetchStatus()

            commits = try await fetchedCommits
            currentChanges = try await fetchedStatus

            print("[JJRepository] Loaded \(commits.count) commits, \(currentChanges.count) changes")

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
                    print("[JJRepository] Auto-selected working copy: \(workingCopy.shortChangeId)")
                }
            } else if let selected = currentSelection {
                // Refresh changes for current selection
                selectedCommitChanges = try await runner.fetchDiff(revision: selected.changeId)
            }
        } catch {
            print("[JJRepository] Error: \(error)")
            self.error = error
        }

        isLoading = false
        isRefreshing = false
    }

    func selectCommit(_ commit: Commit?) async {
        selectedCommit = commit

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
}
