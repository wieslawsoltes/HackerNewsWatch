import Foundation

@MainActor
final class CommentsViewModel: ObservableObject {
    @Published var root: CommentNode?
    @Published var isLoading = false
    @Published var error: String?
    @Published var loadingProgress: Double = 0.0
    
    private let service = HNService()
    private var totalComments = 0
    private var loadedComments = 0
    
    struct CommentNode: Identifiable {
        let id: Int
        let comment: HNComment
        var children: [CommentNode]
        var isChildrenLoaded: Bool = false
        
        init(id: Int, comment: HNComment, children: [CommentNode] = [], isChildrenLoaded: Bool = false) {
            self.id = id
            self.comment = comment
            self.children = children
            self.isChildrenLoaded = isChildrenLoaded
        }
    }
    
    func load(for story: HNStory) async {
        isLoading = true
        error = nil
        loadingProgress = 0.0
        loadedComments = 0
        
        defer { isLoading = false }
        
        do {
            let kids = story.kids ?? []
            totalComments = kids.count
            
            // Create root node immediately
            self.root = CommentNode(
                id: story.id,
                comment: HNComment(id: story.id, by: nil, text: "", time: nil, kids: story.kids, deleted: nil, dead: nil),
                children: [],
                isChildrenLoaded: false
            )
            
            // Load top-level comments progressively
            let rootChildren = await loadNodesProgressively(ids: kids)
            
            // Update root with loaded children
            self.root = CommentNode(
                id: story.id,
                comment: self.root!.comment,
                children: rootChildren,
                isChildrenLoaded: true
            )
            
            loadingProgress = 1.0
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func loadChildren(for nodeId: Int) async {
        guard let root = root else { return }
        
        let updatedRoot = await loadChildrenForNode(root, targetId: nodeId)
        self.root = updatedRoot
    }
    
    private func loadChildrenForNode(_ node: CommentNode, targetId: Int) async -> CommentNode {
        if node.id == targetId && !node.isChildrenLoaded {
            let childIds = node.comment.kids ?? []
            let children = await loadNodesProgressively(ids: childIds)
            return CommentNode(
                id: node.id,
                comment: node.comment,
                children: children,
                isChildrenLoaded: true
            )
        }
        
        let updatedChildren = await withTaskGroup(of: CommentNode.self) { group in
            for child in node.children {
                group.addTask {
                    await self.loadChildrenForNode(child, targetId: targetId)
                }
            }
            
            var result: [CommentNode] = []
            for await updatedChild in group {
                result.append(updatedChild)
            }
            return result
        }
        
        return CommentNode(
            id: node.id,
            comment: node.comment,
            children: updatedChildren,
            isChildrenLoaded: node.isChildrenLoaded
        )
    }
    
    private func loadNodesProgressively(ids: [Int]) async -> [CommentNode] {
        var nodes: [CommentNode] = []
        nodes.reserveCapacity(ids.count)
        
        for id in ids {
            do {
                let c: HNComment = try await service.item(id)
                if c.deleted == true || c.dead == true { continue }
                
                // Create node without loading children initially
                let node = CommentNode(
                    id: c.id,
                    comment: c,
                    children: [],
                    isChildrenLoaded: (c.kids?.isEmpty ?? true)
                )
                nodes.append(node)
                
                // Update progress
                loadedComments += 1
                if totalComments > 0 {
                    loadingProgress = Double(loadedComments) / Double(totalComments)
                }
                
                // Yield control to allow UI updates
                await Task.yield()
                
            } catch {
                continue
            }
        }
        return nodes
    }
}
