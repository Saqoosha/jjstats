import SwiftUI

struct FileChangeRow: View {
    let change: FileChange

    private var statusColor: Color {
        switch change.status {
        case .added: return .green
        case .deleted: return .red
        case .modified: return .orange
        case .renamed, .copied: return .blue
        }
    }

    private var statusIcon: String {
        switch change.status {
        case .added: return "plus.circle.fill"
        case .deleted: return "minus.circle.fill"
        case .modified: return "pencil.circle.fill"
        case .renamed: return "arrow.right.circle.fill"
        case .copied: return "doc.on.doc.fill"
        }
    }

    private var statusTooltip: String {
        switch change.status {
        case .added: return "Added"
        case .deleted: return "Deleted"
        case .modified: return "Modified"
        case .renamed: return "Renamed"
        case .copied: return "Copied"
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            // Status indicator - modern icon style
            Image(systemName: statusIcon)
                .font(.system(size: 14))
                .foregroundStyle(statusColor)
                .frame(width: 18)
                .help(statusTooltip)

            // File path with proper truncation
            Text(change.path)
                .font(.system(size: 14, design: .monospaced))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
    }
}
