import SwiftUI

struct FileChangeRow: View {
    let change: FileChange

    var statusColor: Color {
        switch change.status {
        case .added: return .green
        case .deleted: return .red
        case .modified: return .orange
        case .renamed, .copied: return .blue
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(change.status.rawValue)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.medium)
                .foregroundStyle(statusColor)
                .frame(width: 16)

            Text(change.path)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()
        }
        .padding(.vertical, 2)
    }
}
