import Foundation

@MainActor
final class FeedViewModel: ObservableObject {
    static let shared = FeedViewModel()
    
    @Published var stories: [HNStory] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var error: String?
    @Published var feedType: FeedType = .top
    @Published var isLiveMode = false
    
    private let service = HNService()
    private var allStoryIDs: [Int] = []
    private let batchSize = 10
    private var currentBatch = 0
    private var liveUpdateTimer: Timer?
    
    func load() async {
        isLoading = true
        error = nil
        currentBatch = 0
        stories = []
        
        defer { isLoading = false }
        
        do {
            allStoryIDs = try await service.storyIDs(for: feedType)
            await loadNextBatch()
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func changeFeed(to newFeedType: FeedType) async {
        guard newFeedType != feedType else { return }
        feedType = newFeedType
        await load()
    }
    
    func loadMore() async {
        guard !isLoadingMore && hasMoreStories else { return }
        await loadNextBatch()
    }
    
    var hasMoreStories: Bool {
        currentBatch * batchSize < allStoryIDs.count
    }
    
    private func loadNextBatch() async {
        isLoadingMore = true
        defer { isLoadingMore = false }
        
        let startIndex = currentBatch * batchSize
        let endIndex = min(startIndex + batchSize, allStoryIDs.count)
        
        guard startIndex < allStoryIDs.count else { return }
        
        let batchIDs = Array(allStoryIDs[startIndex..<endIndex])
        var batchStories: [HNStory] = []
        
        for id in batchIDs {
            do {
                let story: HNStory = try await service.item(id)
                batchStories.append(story)
                
                // Add story immediately for progressive loading
                stories.append(story)
            } catch {
                continue
            }
        }
        
        currentBatch += 1
    }
    
    private func setupLiveUpdates() {
        guard isLiveMode else { return }
        liveUpdateTimer?.invalidate()
        
        // Use timer for periodic updates
        liveUpdateTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.load()
            }
        }
    }
    
    private func loadNewStories(_ newIDs: [Int]) async {
        for id in newIDs.prefix(5) { // Limit to 5 new stories at once
            do {
                let story: HNStory = try await service.item(id)
                // Insert at the beginning for new stories
                if !stories.contains(where: { $0.id == story.id }) {
                    stories.insert(story, at: 0)
                }
            } catch {
                continue
            }
        }
    }
    
    private func reorderStories() {
        // Reorder stories to match the order in allStoryIDs
        let orderedStories = allStoryIDs.compactMap { id in
            stories.first { $0.id == id }
        }
        stories = orderedStories
    }
    
    func toggleLiveMode() {
        if isLiveMode {
            // Switch to static mode
            liveUpdateTimer?.invalidate()
            isLiveMode = false
            Task {
                await load()
            }
        } else {
            // Switch to live mode
            isLiveMode = true
            setupLiveUpdates()
        }
    }
    
    deinit {
        liveUpdateTimer?.invalidate()
    }
}
