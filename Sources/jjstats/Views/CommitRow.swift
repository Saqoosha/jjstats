import SwiftUI

struct CommitRow: View {
    let commit: Commit
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Working copy indicator
            Text(commit.isWorkingCopy ? "@" : "○")
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(commit.isWorkingCopy ? .blue : .secondary)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                // Change ID + Bookmarks
                HStack(spacing: 4) {
                    Text(commit.shortChangeId)
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(commit.isWorkingCopy ? .semibold : .regular)
                        .foregroundStyle(commit.isWorkingCopy ? .primary : .secondary)

                    // Bookmark badges
                    ForEach(commit.localBookmarks, id: \.self) { bookmark in
                        BookmarkBadge(
                            name: bookmark,
                            isSynced: commit.isBookmarkSynced(bookmark)
                        )
                    }
                }

                // Description
                Text(commit.shortDescription)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        .contentShape(Rectangle())
    }
}

struct BookmarkBadge: View {
    let name: String
    let isSynced: Bool

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: isSynced ? "checkmark.circle.fill" : "arrow.up.circle")
                .font(.system(size: 10))
            Text(name)
                .font(.system(size: 10, weight: .medium))
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(isSynced ? Color.teal.opacity(0.25) : Color.orange.opacity(0.3))
        .foregroundStyle(isSynced ? Color(red: 0, green: 0.5, blue: 0.5) : Color(red: 0.8, green: 0.4, blue: 0))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
