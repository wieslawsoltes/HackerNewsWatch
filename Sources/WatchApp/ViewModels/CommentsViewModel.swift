import Foundation

@MainActor
final class CommentsViewModel: ObservableObject {
    @Published var root: CommentNode?
    @Published var isLoading = false
    @Published var error: String?
    
    private let service = HNService()
    
    struct CommentNode: Identifiable {
        let id: Int
        let comment: HNComment
        let children: [CommentNode]
    }
    
    func load(for story: HNStory) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let kids = story.kids ?? []
            let rootChildren = try await loadNodes(ids: kids)
            self.root = CommentNode(id: story.id, comment: HNComment(id: story.id, by: nil, text: "", time: nil, kids: story.kids, deleted: nil, dead: nil), children: rootChildren)
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    private func loadNodes(ids: [Int]) async throws -> [CommentNode] {
        var nodes: [CommentNode] = []
        nodes.reserveCapacity(ids.count)
        for id in ids {
            do {
                let c: HNComment = try await service.item(id)
                if c.deleted == true || c.dead == true { continue }
                let children = try await loadNodes(ids: c.kids ?? [])
                nodes.append(CommentNode(id: c.id, comment: c, children: children))
            } catch {
                continue
            }
        }
        return nodes
    }
}
