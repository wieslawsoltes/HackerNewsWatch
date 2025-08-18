import Foundation

@MainActor
final class FeedViewModel: ObservableObject {
    static let shared = FeedViewModel()
    
    @Published var stories: [HNStory] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var error: String?
    @Published var feedType: FeedType = .top
    
    private let service = HNService()
    private var allStoryIDs: [Int] = []
    private let batchSize = 10
    private var currentBatch = 0
    
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
}
