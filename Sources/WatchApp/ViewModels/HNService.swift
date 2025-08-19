import Foundation

enum FeedType: String, CaseIterable {
    case top = "topstories"
    case new = "newstories"
    case best = "beststories"
    case ask = "askstories"
    case show = "showstories"
    case job = "jobstories"
    
    var displayName: String {
        switch self {
        case .top: return "Top"
        case .new: return "New"
        case .best: return "Best"
        case .ask: return "Ask HN"
        case .show: return "Show HN"
        case .job: return "Jobs"
        }
    }
    
    var systemImage: String {
        switch self {
        case .top: return "flame.fill"
        case .new: return "clock.fill"
        case .best: return "star.fill"
        case .ask: return "questionmark.circle.fill"
        case .show: return "eye.fill"
        case .job: return "briefcase.fill"
        }
    }
}

struct AlgoliaSearchResponse: Decodable {
    let hits: [AlgoliaHit]
    let nbHits: Int
    let nbPages: Int
    let page: Int
}

struct AlgoliaHit: Decodable {
    let objectID: String
    let title: String?
    let author: String?
    let url: String?
    let points: Int?
    let num_comments: Int?
    let created_at_i: Int?
    
    func toHNStory() -> HNStory? {
        guard let title = title,
              let id = Int(objectID) else { return nil }
        
        return HNStory(
            id: id,
            title: title,
            by: author,
            url: url,
            score: points,
            time: created_at_i,
            descendants: num_comments,
            kids: nil
        )
    }
}

actor HNService {
    private let base = URL(string: "https://hacker-news.firebaseio.com/v0")!
    private let algoliaBase = URL(string: "https://hn.algolia.com/api/v1")!
    private let session: URLSession = .shared
    
    func topStoryIDs() async throws -> [Int] {
        return try await storyIDs(for: .top)
    }
    
    func storyIDs(for feedType: FeedType) async throws -> [Int] {
        let url = base.appendingPathComponent("\(feedType.rawValue).json")
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode([Int].self, from: data)
    }
    
    func item<T: Decodable>(_ id: Int) async throws -> T {
        let url = base.appendingPathComponent("item/\(id).json")
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    func user(_ username: String) async throws -> HNUser {
        let url = base.appendingPathComponent("user/\(username).json")
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(HNUser.self, from: data)
    }
    
    func searchStories(query: String, page: Int = 0) async throws -> (stories: [HNStory], page: Int, nbPages: Int) {
        guard var components = URLComponents(url: algoliaBase.appendingPathComponent("search"), resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }
        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "tags", value: "story"),
            URLQueryItem(name: "page", value: String(page))
        ]
        guard let url = components.url else { throw URLError(.badURL) }
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let decoded = try JSONDecoder().decode(AlgoliaSearchResponse.self, from: data)
        let stories = decoded.hits.compactMap { $0.toHNStory() }
        return (stories, decoded.page, decoded.nbPages)
    }
}
