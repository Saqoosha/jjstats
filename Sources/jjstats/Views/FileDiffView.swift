import SwiftUI

struct FileDiffView: View {
    let fileDiff: FileDiff
    let fileChange: FileChange

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            DiffHeaderView(
                path: fileDiff.path,
                status: fileChange.status,
                stats: fileDiff.stats
            )

            Divider()

            if fileDiff.hunks.isEmpty {
                emptyDiffView
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(fileDiff.hunks) { hunk in
                            DiffHunkView(hunk: hunk)
                        }
                    }
                }
            }
        }
        .background(Color(nsColor: .textBackgroundColor))
    }

    private var emptyDiffView: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.text")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(.tertiary)
            Text("No changes")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Header

struct DiffHeaderView: View {
    let path: String
    let status: FileChangeStatus
    let stats: DiffStats

    private var statusColor: Color {
        switch status {
        case .added: return .green
        case .deleted: return .red
        case .modified: return .orange
        case .renamed, .copied: return .blue
        }
    }

    private var statusIcon: String {
        switch status {
        case .added: return "plus.circle.fill"
        case .deleted: return "minus.circle.fill"
        case .modified: return "pencil.circle.fill"
        case .renamed: return "arrow.right.circle.fill"
        case .copied: return "doc.on.doc.fill"
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: statusIcon)
                .font(.system(size: 14))
                .foregroundStyle(statusColor)

            Text(path)
                .font(.system(size: 13, design: .monospaced))
                .fontWeight(.medium)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            HStack(spacing: 8) {
                Text("+\(stats.additions)")
                    .foregroundStyle(.green)
                Text("-\(stats.deletions)")
                    .foregroundStyle(.red)
            }
            .font(.system(size: 12, design: .monospaced))
            .fontWeight(.medium)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

// MARK: - Hunk

struct DiffHunkView: View {
    let hunk: DiffHunk

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(hunk.header)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.08))

            ForEach(hunk.lines) { line in
                DiffLineView(line: line)
            }
        }
    }
}

// MARK: - Line

struct DiffLineView: View {
    let line: DiffLine

    private var backgroundColor: Color {
        switch line.type {
        case .addition: return Color.green.opacity(0.15)
        case .deletion: return Color.red.opacity(0.15)
        case .context: return .clear
        }
    }

    private var lineNumberColor: Color {
        .secondary.opacity(0.6)
    }

    private var linePrefix: String {
        switch line.type {
        case .addition: return "+"
        case .deletion: return "-"
        case .context: return " "
        }
    }

    private var prefixColor: Color {
        switch line.type {
        case .addition: return .green
        case .deletion: return .red
        case .context: return .clear
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Old line number
            Text(line.oldLineNumber.map { String($0) } ?? "")
                .frame(width: 40, alignment: .trailing)
                .padding(.trailing, 4)
                .foregroundStyle(lineNumberColor)

            // New line number
            Text(line.newLineNumber.map { String($0) } ?? "")
                .frame(width: 40, alignment: .trailing)
                .padding(.trailing, 8)
                .foregroundStyle(lineNumberColor)

            // +/- sign
            Text(linePrefix)
                .frame(width: 14)
                .foregroundStyle(prefixColor)

            // Content
            Text(line.content)
                .textSelection(.enabled)

            Spacer(minLength: 0)
        }
        .font(.system(size: 12, design: .monospaced))
        .padding(.vertical, 1)
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundColor)
    }
}
