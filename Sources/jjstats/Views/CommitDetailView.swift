import SwiftUI

struct CommitDetailView: View {
    let commit: Commit
    let changes: [FileChange]

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: commit.timestamp)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Card
                metadataSection

                // Description Section
                descriptionSection

                // Bookmarks Section
                if !commit.bookmarks.isEmpty {
                    bookmarksSection
                }

                // Changed Files Section
                changedFilesSection

                Spacer(minLength: 20)
            }
            .padding(20)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Metadata Section

    private var metadataSection: some View {
        GroupBox {
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                GridRow {
                    MetadataLabel(icon: "number", text: "Change")
                    HStack(spacing: 8) {
                        Text(commit.shortChangeId)
                            .font(.system(size: 14, design: .monospaced))
                            .fontWeight(.medium)
                        if commit.isWorkingCopy {
                            WorkingCopyBadge()
                        }
                    }
                }

                if !commit.author.isEmpty {
                    GridRow {
                        MetadataLabel(icon: "person", text: "Author")
                        Text(commit.author)
                            .font(.system(size: 14))
                    }
                }

                GridRow {
                    MetadataLabel(icon: "calendar", text: "Date")
                    Text(formattedDate)
                        .font(.system(size: 14))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Description Section

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Description")

            GroupBox {
                Text(commit.description.isEmpty ? "(no description)" : commit.description)
                    .font(.system(size: 14))
                    .foregroundStyle(commit.description.isEmpty ? .secondary : .primary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Bookmarks Section

    private var bookmarksSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Bookmarks")

            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(commit.localBookmarks, id: \.self) { bookmark in
                        BookmarkRow(
                            name: bookmark,
                            isSynced: commit.isBookmarkSynced(bookmark),
                            isRemoteOnly: false
                        )
                    }

                    // Remote-only bookmarks
                    ForEach(commit.remoteBookmarks.filter { remote in
                        !commit.localBookmarks.contains { remote.hasPrefix("\($0)@") }
                    }, id: \.self) { bookmark in
                        BookmarkRow(
                            name: bookmark,
                            isSynced: false,
                            isRemoteOnly: true
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Changed Files Section

    private var changedFilesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                SectionHeader(title: "Changed Files")
                Text("\(changes.count)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.12), in: Capsule())
            }

            GroupBox {
                if changes.isEmpty {
                    Text("No changes")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 14))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(changes.enumerated()), id: \.element.id) { index, change in
                            FileChangeRow(change: change)
                            if index < changes.count - 1 {
                                Divider()
                                    .padding(.leading, 24)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct MetadataLabel: View {
    let icon: String
    let text: String

    var body: some View {
        Label {
            Text(text)
                .foregroundStyle(.secondary)
        } icon: {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
        }
        .font(.system(size: 14))
    }
}

struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.primary)
    }
}

struct WorkingCopyBadge: View {
    var body: some View {
        Text("@")
            .font(.system(size: 12, weight: .bold, design: .monospaced))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.accentColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
            .foregroundStyle(Color.accentColor)
    }
}

struct BookmarkRow: View {
    let name: String
    let isSynced: Bool
    let isRemoteOnly: Bool

    private var icon: String {
        if isRemoteOnly { return "cloud" }
        return isSynced ? "checkmark.circle.fill" : "arrow.up.circle.fill"
    }

    private var iconColor: Color {
        if isRemoteOnly { return .blue }
        return isSynced ? .teal : .orange
    }

    private var statusText: String {
        if isRemoteOnly { return "remote only" }
        return isSynced ? "synced" : "not pushed"
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(iconColor)
                .frame(width: 18)

            Text(name)
                .font(.system(size: 14, design: .monospaced))

            Text("(\(statusText))")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Empty Detail View

struct EmptyDetailView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.tertiary)

            Text("Select a commit")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            Text("Choose a commit from the list to view its details")
                .font(.system(size: 14))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
