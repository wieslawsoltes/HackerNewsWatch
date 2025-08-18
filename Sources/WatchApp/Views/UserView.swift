import SwiftUI

struct UserView: View {
    let username: String
    @StateObject private var vm = UserViewModel()
    @StateObject private var savedArticlesManager = SavedArticlesManager.shared
    
    var body: some View {
        NavigationStack {
            List {
                if vm.isLoading {
                    HStack {
                        Spacer()
                        ProgressView("Loading user…")
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                } else if let error = vm.error {
                    VStack(spacing: 8) {
                        Text("Error: \(error)")
                        Button("Retry") { 
                            Task { await vm.loadUser(username) } 
                        }
                    }
                    .listRowBackground(Color.clear)
                } else if let user = vm.user {
                    // User details section
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .foregroundStyle(.orange)
                                    .font(.title2)
                                Text(user.id)
                                    .font(.headline)
                                    .foregroundStyle(.orange)
                            }
                            
                            if let karma = user.karma {
                                HStack {
                                    Image(systemName: "star.fill")
                                        .foregroundStyle(.secondary)
                                    Text("Karma: \(karma)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundStyle(.secondary)
                                Text("Joined: \(user.formattedCreated)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            if let about = user.about, !about.isEmpty {
                                Text(about.htmlDecoded)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 4)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // User stories section
                    if !vm.userStories.isEmpty {
                        Section("Stories") {
                            ForEach(vm.userStories) { story in
                                NavigationLink(value: story) {
                                    UserStoryRow(story: story, savedArticlesManager: savedArticlesManager)
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.carousel)
            .scrollBounceBehavior(.always)
            .navigationTitle("@\(username)")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: HNStory.self) { story in
                CommentsView(story: story)
            }
            .onAppear {
                if vm.user == nil {
                    Task { await vm.loadUser(username) }
                }
            }
        }
    }
}

struct UserStoryRow: View {
    let story: HNStory
    @ObservedObject var savedArticlesManager: SavedArticlesManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(story.title)
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    if let score = story.score {
                        Image(systemName: "arrowtriangle.up.fill")
                            .foregroundStyle(.orange)
                            .font(.caption2)
                        Text("\(score)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    let commentsCount = story.descendants ?? story.kids?.count
                    if let count = commentsCount {
                        HStack(spacing: 2) {
                            Image(systemName: "text.bubble")
                                .foregroundStyle(.secondary)
                                .font(.caption2)
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
                    .font(.caption)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 2)
    }
}

// Extension to decode HTML entities
extension String {
    var htmlDecoded: String {
        guard let data = self.data(using: .utf8) else { return self }
        
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        
        guard let attributedString = try? NSAttributedString(data: data, options: options, documentAttributes: nil) else {
            return self
        }
        
        return attributedString.string
    }
}