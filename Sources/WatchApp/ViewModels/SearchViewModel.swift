import Foundation

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var results: [HNStory] = []
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var page: Int = 0
    @Published var nbPages: Int = 0
    
    private let service = HNService()
    
    func search(reset: Bool = true) async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            results = []
            page = 0
            nbPages = 0
            return
        }
        
        if reset {
            page = 0
            results = []
        }
        
        isLoading = true
        error = nil
        defer { isLoading = false }
        
        do {
            let response = try await service.searchStories(query: query, page: page)
            if reset {
                results = response.stories
            } else {
                results += response.stories
            }
            page = response.page
            nbPages = response.nbPages
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    var canLoadMore: Bool {
        return page + 1 < nbPages && !isLoading
    }
    
    func loadMoreIfNeeded() async {
        guard canLoadMore else { return }
        page += 1
        await search(reset: false)
    }
}