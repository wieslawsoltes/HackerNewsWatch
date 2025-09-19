import SwiftUI

struct SavedArticlesView: View {
    @StateObject private var savedArticlesManager = SavedArticlesManager.shared
    @State private var selectedUser: String?
    
    var body: some View {
        NavigationStack {
            List {
                if savedArticlesManager.savedStories.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "bookmark")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No saved articles")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Tap the bookmark icon on any story to save it for later")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .listRowBackground(Color.clear)
                    .padding(.vertical, 20)
                } else {
                    ForEach(savedArticlesManager.savedStories) { story in
                        NavigationLink(value: story) {
                            StoryRow(
                                story: story,
                                savedArticlesManager: savedArticlesManager,
                                onUserSelected: { username in
                                    selectedUser = username
                                }
                            )
                        }
                    }
                    .onDelete(perform: deleteStories)
                }
            }
            .listStyle(.carousel)
            .navigationTitle("Saved Articles")
            .navigationDestination(for: HNStory.self) { story in
                CommentsView(story: story)
            }
            .navigationDestination(item: $selectedUser) { username in
                UserDetailsView(username: username)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await savedArticlesManager.reloadSavedStories()
                        }
                    } label: {
                        if savedArticlesManager.isReloading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .disabled(savedArticlesManager.savedStories.isEmpty || savedArticlesManager.isReloading)
                }
            }
        }
    }

    private func deleteStories(at offsets: IndexSet) {
        for index in offsets {
            let story = savedArticlesManager.savedStories[index]
            savedArticlesManager.removeStory(story)
        }
    }
}

#Preview {
    SavedArticlesView()
}
