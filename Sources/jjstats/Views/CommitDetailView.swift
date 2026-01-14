import SwiftUI

struct CommitDetailView: View {
    let commit: Commit
    let changes: [FileChange]
    @Bindable var repository: JJRepository

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    private var formattedDate: String {
        Self.dateFormatter.string(from: commit.timestamp)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Card
                metadataSection

                // Description Section
                descriptionSection

                // Changed Files Section
                changedFilesSection

                // Diff Section
                if let fileDiff = repository.selectedFileDiff,
                   let fileChange = repository.selectedFileChange {
                    diffSection(fileDiff: fileDiff, fileChange: fileChange)
                } else {
                    Spacer(minLength: 20)
                }
            }
            .padding(20)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Metadata Section

    private var metadataSection: some View {
        GroupBox {
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 0) {
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
                .frame(height: 28)

                if !commit.author.isEmpty {
                    GridRow {
                        MetadataLabel(icon: "person", text: "Author")
                        Text(commit.author)
                            .font(.system(size: 14))
                    }
                    .frame(height: 28)
                }

                GridRow {
                    MetadataLabel(icon: "calendar", text: "Date")
                    Text(formattedDate)
                        .font(.system(size: 14))
                }
                .frame(height: 28)

                if let signatureStatus = commit.signatureStatus {
                    let badge = SignatureBadge(status: signatureStatus)
                    GridRow {
                        MetadataLabel(icon: "signature", text: "Signature")
                        HStack(spacing: 6) {
                            Image(systemName: badge.icon)
                                .font(.system(size: 14))
                                .foregroundStyle(badge.color)
                            Text(badge.text)
                                .font(.system(size: 14))
                                .foregroundStyle(badge.color)
                        }
                    }
                    .frame(height: 28)
                }

                if !commit.bookmarks.isEmpty {
                    GridRow {
                        MetadataLabel(icon: "bookmark", text: "Bookmarks")
                        FlowLayout(spacing: 6) {
                            ForEach(commit.localBookmarks, id: \.self) { bookmark in
                                BookmarkBadge(name: bookmark, isSynced: commit.isBookmarkSynced(bookmark))
                            }
                            ForEach(commit.remoteBookmarks.filter { remote in
                                !commit.localBookmarks.contains { remote.hasPrefix("\($0)@") }
                            }, id: \.self) { bookmark in
                                RemoteBookmarkBadge(name: bookmark)
                            }
                        }
                    }
                    .frame(minHeight: 28)
                }

                if !commit.tags.isEmpty {
                    GridRow {
                        MetadataLabel(icon: "tag", text: "Tags")
                        FlowLayout(spacing: 6) {
                            ForEach(commit.tags, id: \.self) { tag in
                                TagBadge(name: tag)
                            }
                        }
                    }
                    .frame(minHeight: 28)
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
                            FileChangeRow(
                                change: change,
                                isSelected: repository.selectedFileChange?.id == change.id,
                                onTap: {
                                    Task {
                                        if repository.selectedFileChange?.id == change.id {
                                            await repository.selectFileChange(nil)
                                        } else {
                                            await repository.selectFileChange(change)
                                        }
                                    }
                                }
                            )
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

    // MARK: - Diff Section

    private func diffSection(fileDiff: FileDiff, fileChange: FileChange) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Diff")

            FileDiffView(fileDiff: fileDiff, fileChange: fileChange)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
        }
    }
}

// MARK: - Supporting Views

struct MetadataLabel: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .frame(width: 16)
            Text(text)
        }
        .font(.system(size: 14))
        .foregroundStyle(.secondary)
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

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(subviews: subviews, proposal: proposal)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(subviews: subviews, proposal: proposal)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func layout(subviews: Subviews, proposal: ProposedViewSize) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            totalHeight = currentY + lineHeight
        }

        return (CGSize(width: maxWidth, height: totalHeight), positions)
    }
}

// MARK: - Remote Bookmark Badge

struct RemoteBookmarkBadge: View {
    let name: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "cloud")
                .font(.system(size: 11, weight: .medium))
            Text(name)
                .font(.system(size: 12, weight: .medium))
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(Color.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
        .foregroundStyle(Color.blue)
    }
}
