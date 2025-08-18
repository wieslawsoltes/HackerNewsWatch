import SwiftUI

struct FeedView: View {
    @StateObject private var vm = FeedViewModel()
    
    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading && vm.stories.isEmpty {
                    ProgressView("Loading…")
                } else if let error = vm.error {
                    VStack(spacing: 8) {
                        Text("Error: \(error)")
                        Button("Retry") { Task { await vm.load() } }
                    }
                } else {
                    List(vm.stories) { story in
                        NavigationLink(value: story) {
                            StoryRow(story: story)
                        }
                    }
                    .listStyle(.carousel)
                    .refreshable {
                        await vm.load()
                    }
                }
            }
            .navigationDestination(for: HNStory.self) { story in
                CommentsView(story: story)
            }
            .task { await vm.load() }
            .navigationTitle("Hacker News")
        }
    }
}

struct StoryRow: View {
    let story: HNStory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(story.title)
                .font(.headline)
                .foregroundStyle(.orange)
            HStack(spacing: 8) {
                if let score = story.score {
                    Image(systemName: "arrowtriangle.up.fill")
                        .foregroundStyle(.orange)
                    Text("\(score)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                let commentsCount = story.descendants ?? story.kids?.count
                if let count = commentsCount {
                    HStack(spacing: 4) {
                        Image(systemName: "text.bubble")
                            .foregroundStyle(.secondary)
                        Text("\(count)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
