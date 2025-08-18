import SwiftUI

struct FeedView: View {
    @StateObject private var vm = FeedViewModel.shared
    @StateObject private var savedArticlesManager = SavedArticlesManager.shared
    
    var body: some View {
        NavigationStack {
            List {
                if vm.isLoading && vm.stories.isEmpty {
                    HStack {
                        Spacer()
                        ProgressView("Loading…")
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                } else if let error = vm.error {
                    VStack(spacing: 8) {
                        Text("Error: \(error)")
                        Button("Retry") { Task { await vm.load() } }
                    }
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(vm.stories) { story in
                        NavigationLink(value: story) {
                            StoryRow(story: story, savedArticlesManager: savedArticlesManager)
                        }
                    }
                    
                    if vm.hasMoreStories {
                        if vm.isLoadingMore {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .scaleEffect(0.8)
                                Spacer()
                            }
                            .padding(.vertical, 8)
                            .listRowBackground(Color.clear)
                        } else {
                            Button("Load More") {
                                Task { await vm.loadMore() }
                            }
                            .foregroundStyle(.orange)
                            .listRowBackground(Color.clear)
                            .onAppear {
                                Task { await vm.loadMore() }
                            }
                        }
                    }
                }
            }
            .listStyle(.carousel)
            .scrollBounceBehavior(.always)
            .refreshable {
                await vm.load()
            }
            .navigationDestination(for: HNStory.self) { story in
                CommentsView(story: story)
            }
            .navigationDestination(for: String.self) { username in
                UserDetailsView(username: username)
            }
            .onAppear {
                if vm.stories.isEmpty {
                    Task { await vm.load() }
                }
            }
            .navigationTitle(vm.feedType.displayName)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        Task { await vm.load() }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(.orange)
                    }
                    .buttonStyle(.plain)
                    .disabled(vm.isLoading)
                }
            }
        }
    }
}

struct StoryRow: View {
    let story: HNStory
    @ObservedObject var savedArticlesManager: SavedArticlesManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(story.title)
                    .font(.headline)
                    .foregroundStyle(.orange)
                HStack(spacing: 8) {
                    if let by = story.by {
                        NavigationLink(value: by) {
                            Image(systemName: "person.circle")
                                .foregroundStyle(.orange)
                                .font(.caption)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
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
            
            Spacer()
            
            Button(action: {
                savedArticlesManager.toggleSaveStory(story)
            }) {
                Image(systemName: savedArticlesManager.isStorySaved(story) ? "bookmark.fill" : "bookmark")
                    .foregroundStyle(.orange)
                    .font(.title3)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 4)
    }
}
