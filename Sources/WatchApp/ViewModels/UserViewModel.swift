import Foundation

@MainActor
class UserViewModel: ObservableObject {
    @Published var user: HNUser?
    @Published var userStories: [HNStory] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let service = HNService()
    private let maxStoriesToLoad = 20
    
    func loadUser(_ username: String) async {
        isLoading = true
        error = nil
        
        do {
            // Load user details
            let fetchedUser = try await service.user(username)
            user = fetchedUser
            
            // Load user's submitted stories (first 20)
            if let submittedIds = fetchedUser.submitted?.prefix(maxStoriesToLoad) {
                var stories: [HNStory] = []
                
                for id in submittedIds {
                    do {
                        let story: HNStory = try await service.item(id)
                        stories.append(story)
                    } catch {
                        // Skip items that can't be loaded (might be comments, deleted items, etc.)
                        continue
                    }
                }
                
                userStories = stories
            }
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
}