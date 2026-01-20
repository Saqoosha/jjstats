import SwiftUI

struct CommitRow: View {
    let commit: Commit
    let isSelected: Bool
    let repository: JJRepository

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    private var relativeTime: String {
        Self.relativeFormatter.localizedString(for: commit.timestamp, relativeTo: Date())
    }

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                // First line: Change ID + Timestamp
                HStack(spacing: 6) {
                    Text(commit.shortChangeId)
                        .font(.system(size: 14, weight: commit.isWorkingCopy ? .semibold : .regular, design: .monospaced))
                        .foregroundStyle(commit.isWorkingCopy ? .primary : .secondary)

                    Spacer()

                    // Timestamp (auto-updates every minute)
                    TimelineView(.periodic(from: .now, by: 60)) { _ in
                        Text(relativeTime)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }

                // Second line: Description + Signature + Tags + Bookmarks
                HStack(spacing: 6) {
                    Text(commit.shortDescription)
                        .font(.system(size: 14))
                        .foregroundStyle(repository.isOrphaned(commit) ? .secondary : .primary)
                        .lineLimit(1)

                    // Orphaned badge
                    if repository.isOrphaned(commit) {
                        OrphanedBadge()
                    }

                    // Signature indicator
                    if commit.isSigned {
                        SignatureBadge(status: commit.signatureStatus ?? "unknown")
                    }

                    // Tag badges
                    ForEach(commit.tags, id: \.self) { tag in
                        TagBadge(name: tag)
                    }

                    // Bookmark badges
                    ForEach(commit.localBookmarks, id: \.self) { bookmark in
                        BookmarkBadge(
                            name: bookmark,
                            isSynced: commit.isBookmarkSynced(bookmark)
                        )
                    }

                    // Remote-only bookmark badges
                    ForEach(commit.remoteOnlyBookmarks, id: \.self) { bookmark in
                        RemoteBookmarkBadge(name: bookmark)
                    }
                }
            }
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

// MARK: - Tag Badge

struct TagBadge: View {
    let name: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "tag.fill")
                .font(.system(size: 10, weight: .medium))
            Text(name)
                .font(.system(size: 12, weight: .medium))
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(Color.purple.opacity(0.12), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
        .foregroundStyle(Color.purple)
    }
}

// MARK: - Orphaned Badge

struct OrphanedBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 10, weight: .medium))
            Text("orphaned")
                .font(.system(size: 12, weight: .medium))
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(Color.gray.opacity(0.15), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
        .foregroundStyle(Color.secondary)
        .help("Empty change with no bookmarks - can be safely abandoned")
    }
}

// MARK: - Signature Badge

struct SignatureBadge: View {
    let status: String

    private var isError: Bool {
        status.lowercased().hasPrefix("error") || status.lowercased().contains("error:")
    }

    var icon: String {
        if isError {
            return "exclamationmark.triangle.fill"
        }
        switch status {
        case "good": return "checkmark.seal.fill"
        case "bad": return "xmark.seal.fill"
        default: return "questionmark.seal.fill"
        }
    }

    var color: Color {
        if isError {
            return .orange
        }
        switch status {
        case "good": return .green
        case "bad": return .red
        default: return .gray
        }
    }

    var text: String {
        if isError {
            return "Verification Error"
        }
        switch status {
        case "good": return "Verified"
        case "bad": return "Invalid"
        default: return status.capitalized
        }
    }

    var helpText: String {
        if isError {
            // Extract meaningful part of error message
            return status
        }
        switch status {
        case "good": return "Signature verified"
        case "bad": return "Signature is invalid"
        default: return "Signature status: \(status)"
        }
    }

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(color)
            .help(helpText)
    }
}
