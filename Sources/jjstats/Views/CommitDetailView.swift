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
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Change:")
                            .foregroundStyle(.secondary)
                        Text(commit.shortChangeId)
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.semibold)
                        if commit.isWorkingCopy {
                            Text("@")
                                .font(.system(.caption, design: .monospaced))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.blue.opacity(0.2))
                                .foregroundStyle(.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }

                    if !commit.author.isEmpty {
                        HStack {
                            Text("Author:")
                                .foregroundStyle(.secondary)
                            Text(commit.author)
                        }
                    }

                    HStack {
                        Text("Date:")
                            .foregroundStyle(.secondary)
                        Text(formattedDate)
                    }
                }
                .font(.body)

                Divider()

                // Description
                VStack(alignment: .leading, spacing: 4) {
                    Text("Description")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Text(commit.description.isEmpty ? "(no description)" : commit.description)
                        .font(.body)
                        .foregroundStyle(commit.description.isEmpty ? .secondary : .primary)
                        .textSelection(.enabled)
                }

                Divider()

                // Changed files
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Changed Files")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        Text("(\(changes.count))")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                    }

                    if changes.isEmpty {
                        Text("No changes")
                            .foregroundStyle(.secondary)
                            .font(.body)
                    } else {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(changes) { change in
                                FileChangeRow(change: change)
                            }
                        }
                    }
                }

                Spacer()
            }
            .padding()
        }
    }
}

struct EmptyDetailView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Select a commit")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
