import SwiftUI

struct CommitRow: View {
    let commit: Commit
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Working copy indicator - modern dot style
            WorkingCopyIndicator(isWorkingCopy: commit.isWorkingCopy)

            VStack(alignment: .leading, spacing: 4) {
                // Change ID + Bookmarks
                HStack(spacing: 6) {
                    Text(commit.shortChangeId)
                        .font(.system(size: 14, weight: commit.isWorkingCopy ? .semibold : .regular, design: .monospaced))
                        .foregroundStyle(commit.isWorkingCopy ? .primary : .secondary)

                    // Bookmark badges - more subtle design
                    ForEach(commit.localBookmarks, id: \.self) { bookmark in
                        BookmarkBadge(
                            name: bookmark,
                            isSynced: commit.isBookmarkSynced(bookmark)
                        )
                    }
                }

                // Description
                Text(commit.shortDescription)
                    .font(.system(size: 14))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .contentShape(Rectangle())
    }
}

// MARK: - Working Copy Indicator

struct WorkingCopyIndicator: View {
    let isWorkingCopy: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(isWorkingCopy ? Color.accentColor : Color.clear)
                .frame(width: 8, height: 8)

            Circle()
                .strokeBorder(
                    isWorkingCopy ? Color.accentColor : Color.secondary.opacity(0.4),
                    lineWidth: isWorkingCopy ? 0 : 1.5
                )
                .frame(width: 8, height: 8)
        }
        .frame(width: 16, height: 16)
    }
}

// MARK: - Bookmark Badge

struct BookmarkBadge: View {
    let name: String
    let isSynced: Bool

    private var backgroundColor: Color {
        isSynced
            ? Color.teal.opacity(0.12)
            : Color.orange.opacity(0.12)
    }

    private var foregroundColor: Color {
        isSynced
            ? Color.teal
            : Color.orange
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isSynced ? "checkmark.circle.fill" : "arrow.up.circle.fill")
                .font(.system(size: 11, weight: .medium))
            Text(name)
                .font(.system(size: 12, weight: .medium))
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(backgroundColor, in: RoundedRectangle(cornerRadius: 5, style: .continuous))
        .foregroundStyle(foregroundColor)
    }
}
