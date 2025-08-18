import SwiftUI

struct CommentsView: View {
    let story: HNStory
    @StateObject private var vm = CommentsViewModel()
    
    var body: some View {
        List {
            if let url = story.url, let linkURL = URL(string: url) {
                NavigationLink(value: linkURL) {
                    Label("Open Article", systemImage: "doc.text.magnifyingglass")
                        .foregroundStyle(.orange)
                }
            }
            if let root = vm.root {
                CommentTree(node: root, viewModel: vm)
            } else if vm.isLoading {
                VStack(spacing: 8) {
                    ProgressView("Loading comments…")
                    if vm.loadingProgress > 0 {
                        ProgressView(value: vm.loadingProgress)
                            .progressViewStyle(LinearProgressViewStyle())
                        Text("\(Int(vm.loadingProgress * 100))%")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            } else if let error = vm.error {
                Text("Error: \(error)")
            }
        }
        .refreshable {
            await vm.load(for: story)
        }
        .navigationTitle("Comments")
        .navigationDestination(for: URL.self) { url in
            ArticleReaderView(url: url)
        }
        .task { await vm.load(for: story) }
    }
}


struct CommentTree: View {
    let node: CommentsViewModel.CommentNode
    let viewModel: CommentsViewModel
    
    var body: some View {
        ForEach(node.children) { child in
            CommentNodeView(node: child, depth: 0, viewModel: viewModel)
        }
    }
}

struct CommentNodeView: View {
    let node: CommentsViewModel.CommentNode
    let depth: Int
    let viewModel: CommentsViewModel
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 6) {
                if depth > 0 {
                    Rectangle()
                        .fill(Color.orange.opacity(0.4))
                        .frame(width: 2)
                }
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        if let by = node.comment.by {
                            Text(by).font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if hasChildren {
                            Button(action: toggleExpansion) {
                                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    Text(cleanHTML(node.comment.text ?? "[no text]"))
                        .font(.footnote)
                }
            }
            
            if isExpanded {
                if !node.isChildrenLoaded && hasChildren {
                    Button("Load replies") {
                        Task {
                            await viewModel.loadChildren(for: node.id)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .padding(.leading, depth > 0 ? 8 : 0)
                } else if !node.children.isEmpty {
                    ForEach(node.children) { child in
                        CommentNodeView(node: child, depth: depth + 1, viewModel: viewModel)
                    }
                }
            }
        }
    }
    
    private var hasChildren: Bool {
        !(node.comment.kids?.isEmpty ?? true)
    }
    
    private func toggleExpansion() {
        isExpanded.toggle()
    }
    
    private func cleanHTML(_ html: String) -> String {
        var text = html
        let replacements: [(String, String)] = [
            ("<p>", "\n\n"),
            ("<i>", "\u{1F446}"),
        ]
        for (from, to) in replacements {
            text = text.replacingOccurrences(of: from, with: to)
        }
        text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: "&quot;", with: "\"")
        text = text.replacingOccurrences(of: "&apos;", with: "'")
        text = text.replacingOccurrences(of: "&amp;", with: "&")
        text = text.replacingOccurrences(of: "&gt;", with: ">")
        text = text.replacingOccurrences(of: "&lt;", with: "<")
        return text
    }
}
