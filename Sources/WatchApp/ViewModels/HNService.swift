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

actor HNService {
    private let base = URL(string: "https://hacker-news.firebaseio.com/v0")!
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
}
