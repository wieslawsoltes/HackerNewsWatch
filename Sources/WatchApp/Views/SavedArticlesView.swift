import SwiftUI

struct SavedArticlesView: View {
    @StateObject private var savedArticlesManager = SavedArticlesManager.shared
    
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
                            SavedStoryRow(story: story, savedArticlesManager: savedArticlesManager)
                        }
                    }
                    .onDelete(perform: deleteStories)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Saved Articles")
            .navigationDestination(for: HNStory.self) { story in
                CommentsView(story: story)
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

struct SavedStoryRow: View {
    let story: HNStory
    @ObservedObject var savedArticlesManager: SavedArticlesManager
    
    var body: some View {
        HStack {
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
            
            Spacer()
            
            Button(action: {
                savedArticlesManager.removeStory(story)
            }) {
                Image(systemName: "bookmark.fill")
                    .foregroundStyle(.orange)
                    .font(.title3)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SavedArticlesView()
}