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
                // Change ID
                Text(commit.shortChangeId)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(commit.isWorkingCopy ? .semibold : .regular)
                    .foregroundStyle(commit.isWorkingCopy ? .primary : .secondary)

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
