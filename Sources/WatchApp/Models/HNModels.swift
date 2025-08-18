import Foundation

struct HNStory: Identifiable, Codable, Hashable {
    let id: Int
    let title: String
    let url: String?
    let score: Int?
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
