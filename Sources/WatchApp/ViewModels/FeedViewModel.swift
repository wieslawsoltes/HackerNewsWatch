import Foundation

@MainActor
final class FeedViewModel: ObservableObject {
    @Published var stories: [HNStory] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let service = HNService()
    
    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let ids = try await service.topStoryIDs().prefix(50)
            var loaded: [HNStory] = []
            loaded.reserveCapacity(ids.count)
            for id in ids {
                do {
                    let story: HNStory = try await service.item(id)
                    loaded.append(story)
                } catch {
                    continue
                }
            }
            self.stories = loaded
        } catch {
            self.error = error.localizedDescription
        }
    }
}
