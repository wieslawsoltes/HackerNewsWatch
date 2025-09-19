import Foundation

struct HNStory: Identifiable, Codable, Hashable {
    let id: Int
    let title: String
    let by: String?
    let url: String?
    let score: Int?
    let time: Int?
    let descendants: Int?
    let kids: [Int]?
}

struct HNComment: Identifiable, Decodable {
    let id: Int
    let by: String?
    let text: String?
    let time: Int?
    let kids: [Int]?
    let deleted: Bool?
    let dead: Bool?
}

struct HNUser: Identifiable, Decodable {
    let id: String
    let karma: Int?
    let about: String?
    let created: Int?
    let submitted: [Int]?
    
    var formattedCreated: String {
        guard let created = created else { return "Unknown" }
        let date = Date(timeIntervalSince1970: TimeInterval(created))
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

extension String: Identifiable {
    public var id: String { self }
}
