import SwiftUI
import WatchKit

struct FeedView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var vm = FeedViewModel.shared
    @StateObject private var savedArticlesManager = SavedArticlesManager.shared
    @State private var crownValue: Double = 0
    @State private var selectedStoryIndex: Int = 0
    @FocusState private var isCrownFocused: Bool
    
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
            .focusable(true)
            .focused($isCrownFocused)
            .digitalCrownRotation(
                $crownValue,
                from: 0,
                through: Double(max(0, vm.stories.count - 1)),
                by: 1,
                sensitivity: .medium,
                isContinuous: false,
                isHapticFeedbackEnabled: true
            )
            .onChange(of: crownValue) { _, newValue in
                let newIndex = Int(newValue.rounded())
                let maxIndex = max(0, vm.stories.count - 1)
                let clampedIndex = min(max(0, newIndex), maxIndex)
                
                if clampedIndex != selectedStoryIndex && clampedIndex < vm.stories.count {
                    selectedStoryIndex = clampedIndex
                    // Provide haptic feedback for story selection
                    WKInterfaceDevice.current().play(.click)
                }
            }
            .onChange(of: vm.stories.count) { _, _ in
                // Reset crown state when stories count changes
                resetCrownState()
            }
            .navigationDestination(for: HNStory.self) { story in
                CommentsView(story: story)
            }
            .navigationDestination(for: String.self) { value in
                if value == "search" {
                    SearchView()
                } else {
                    UserDetailsView(username: value)
                }
            }
            .onAppear {
                if vm.stories.isEmpty {
                    Task { await vm.load() }
                }
                // Reset crown state when returning to this view
                resetCrownState()
                // Ensure the list regains crown focus after appearing
                DispatchQueue.main.async {
                    isCrownFocused = true
                }
            }
            .onDisappear {
                // Save current crown state when leaving view
                // This helps maintain scroll position context
                isCrownFocused = false
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    // Reapply focus when the scene becomes active again
                    DispatchQueue.main.async {
                        isCrownFocused = true
                    }
                } else {
                    isCrownFocused = false
                }
            }
            .navigationTitle(vm.feedType.displayName)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        vm.toggleLiveMode()
                    }) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(vm.isLiveMode ? .green : .gray)
                                .frame(width: 6, height: 6)
                            Text(vm.isLiveMode ? "LIVE" : "STATIC")
                                .font(.caption2)
                                .foregroundStyle(vm.isLiveMode ? .green : .gray)
                        }
                    }
                    .buttonStyle(.plain)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 8) {
                        NavigationLink(value: "search") {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.orange)
                                .font(.title3)
                        }
                        .background(.regularMaterial, in: Circle())
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            Task { await vm.load() }
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundStyle(.orange)
                                .font(.title3)
                        }
                        .background(.regularMaterial, in: Circle())
                        .buttonStyle(.plain)
                        .disabled(vm.isLoading)
                    }
                }
            }
        }
    }
    
    private func resetCrownState() {
        // Reset crown value to current selected story index to maintain consistency
        crownValue = Double(selectedStoryIndex)
        
        // Ensure selected index is within bounds
        if selectedStoryIndex >= vm.stories.count {
            selectedStoryIndex = max(0, vm.stories.count - 1)
            crownValue = Double(selectedStoryIndex)
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
                    .font(.callout)
                    .fontWeight(.regular)
                    .foregroundStyle(.white)
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
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    let commentsCount = story.descendants ?? story.kids?.count
                    if let count = commentsCount {
                        HStack(spacing: 4) {
                            Image(systemName: "text.bubble")
                                .foregroundStyle(.secondary)
                            Text("\(count)")
                                .font(.caption)
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
            .background(.regularMaterial, in: Circle())
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 4)
    }
}
