import SwiftUI

struct CommitListView: View {
    @Bindable var repository: JJRepository
    @State private var graphLayout: GraphLayoutResult?

    private let rowHeight: CGFloat = 56  // 44 + padding (6 * 2)

    var body: some View {
        ScrollViewReader { proxy in
            List(selection: Binding(
                get: { repository.selectedCommit?.id },
                set: { newValue in
                    Task {
                        let commit = repository.commits.first { $0.id == newValue }
                        await repository.selectCommit(commit)
                    }
                }
            )) {
                ForEach(Array(repository.commits.enumerated()), id: \.element.id) { index, commit in
                    HStack(spacing: 0) {
                        // Graph column
                        if let layout = graphLayout, index < layout.rows.count {
                            GraphColumnView(
                                row: layout.rows[index],
                                rowHeight: rowHeight
                            )
                        }

                        // Commit row
                        CommitRow(
                            commit: commit,
                            isSelected: repository.selectedCommit?.id == commit.id,
                            repository: repository
                        )
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .tag(commit.id)
                    .id(commit.id)
                }
            }
            .listStyle(.sidebar)
            .onChange(of: repository.selectedCommit?.id) { _, newValue in
                if let id = newValue {
                    withAnimation {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }
            .onChange(of: repository.commits) { _, newCommits in
                graphLayout = GraphLayoutCalculator.calculate(commits: newCommits)
            }
            .onAppear {
                graphLayout = GraphLayoutCalculator.calculate(commits: repository.commits)
            }
        }
    }
}
