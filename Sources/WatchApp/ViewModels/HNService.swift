import Foundation

actor HNService {
    private let base = URL(string: "https://hacker-news.firebaseio.com/v0")!
    private let session: URLSession = .shared
    
    func topStoryIDs() async throws -> [Int] {
        let url = base.appendingPathComponent("topstories.json")
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
}
