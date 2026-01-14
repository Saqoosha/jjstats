import SwiftUI

struct CommitListView: View {
    @Bindable var repository: JJRepository

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
                ForEach(repository.commits) { commit in
                    CommitRow(
                        commit: commit,
                        isSelected: repository.selectedCommit?.id == commit.id
                    )
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
        }
    }
}
