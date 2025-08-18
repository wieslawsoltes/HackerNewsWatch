import Foundation

@MainActor
class SavedArticlesManager: ObservableObject {
    @Published var savedStories: [HNStory] = []
    
    private let userDefaults = UserDefaults.standard
    private let savedStoriesKey = "SavedHNStories"
    
    static let shared = SavedArticlesManager()
    
    private init() {
        loadSavedStories()
    }
    
    func saveStory(_ story: HNStory) {
        if !isStorySaved(story) {
            savedStories.append(story)
            persistSavedStories()
        }
    }
    
    func removeStory(_ story: HNStory) {
        savedStories.removeAll { $0.id == story.id }
        persistSavedStories()
    }
    
    func isStorySaved(_ story: HNStory) -> Bool {
        savedStories.contains { $0.id == story.id }
    }
    
    func toggleSaveStory(_ story: HNStory) {
        if isStorySaved(story) {
            removeStory(story)
        } else {
            saveStory(story)
        }
    }
    
    private func loadSavedStories() {
        guard let data = userDefaults.data(forKey: savedStoriesKey),
              let stories = try? JSONDecoder().decode([HNStory].self, from: data) else {
            savedStories = []
            return
        }
        savedStories = stories
    }
    
    private func persistSavedStories() {
        guard let data = try? JSONEncoder().encode(savedStories) else { return }
        userDefaults.set(data, forKey: savedStoriesKey)
    }
    
    func clearAllSavedStories() {
        savedStories.removeAll()
        userDefaults.removeObject(forKey: savedStoriesKey)
    }
}