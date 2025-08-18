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
    
    private func cleanHTML(_ html: String) -> AttributedString {
        var attributedString = AttributedString()
        
        // First, handle HTML entities
        var text = html
        let htmlEntities: [(String, String)] = [
            ("&quot;", "\""),
            ("&apos;", "'"),
            ("&amp;", "&"),
            ("&gt;", ">"),
            ("&lt;", "<"),
            ("&#x27;", "'"),
            ("&#x2F;", "/"),
            ("&#39;", "'"),
            ("&nbsp;", " ")
        ]
        
        for (entity, replacement) in htmlEntities {
            text = text.replacingOccurrences(of: entity, with: replacement)
        }
        
        // Parse HTML tags and apply formatting
        let components = parseHTMLComponents(text)
        
        for component in components {
            var componentString = AttributedString(component.text)
            
            // Apply formatting based on tags
            if component.tags.contains("i") || component.tags.contains("em") {
                componentString.font = .footnote.italic()
            }
            if component.tags.contains("b") || component.tags.contains("strong") {
                componentString.font = .footnote.bold()
            }
            if component.tags.contains("code") {
                componentString.font = .footnote.monospaced()
                componentString.backgroundColor = Color.gray.opacity(0.2)
            }
            if component.tags.contains("a") {
                componentString.foregroundColor = .orange
                componentString.underlineStyle = .single
            }
            
            attributedString.append(componentString)
            
            // Add line breaks for block elements
            if component.tags.contains("p") || component.tags.contains("br") {
                attributedString.append(AttributedString("\n\n"))
            }
        }
        
        return attributedString
    }
    
    private struct HTMLComponent {
        let text: String
        let tags: Set<String>
    }
    
    private func parseHTMLComponents(_ html: String) -> [HTMLComponent] {
        var components: [HTMLComponent] = []
        var currentText = ""
        var tagStack: [String] = []
        var i = html.startIndex
        
        while i < html.endIndex {
            if html[i] == "<" {
                // Save current text if any
                if !currentText.isEmpty {
                    components.append(HTMLComponent(text: currentText, tags: Set(tagStack)))
                    currentText = ""
                }
                
                // Find the end of the tag
                guard let tagEnd = html[i...].firstIndex(of: ">") else {
                    currentText.append(html[i])
                    i = html.index(after: i)
                    continue
                }
                
                let tagContent = String(html[html.index(after: i)..<tagEnd])
                let isClosingTag = tagContent.hasPrefix("/")
                let tagName = isClosingTag ? String(tagContent.dropFirst()) : tagContent.components(separatedBy: " ").first ?? tagContent
                
                if isClosingTag {
                    // Remove from stack
                    if let index = tagStack.lastIndex(of: tagName) {
                        tagStack.remove(at: index)
                    }
                } else {
                    // Add to stack (ignore self-closing tags like <br/>)
                    if !tagContent.hasSuffix("/") && !["br", "hr", "img"].contains(tagName) {
                        tagStack.append(tagName)
                    }
                    
                    // Handle special cases
                    if tagName == "br" {
                        components.append(HTMLComponent(text: "\n", tags: Set(tagStack)))
                    } else if tagName == "p" && !components.isEmpty {
                        components.append(HTMLComponent(text: "\n\n", tags: Set(tagStack)))
                    }
                }
                
                i = html.index(after: tagEnd)
            } else {
                currentText.append(html[i])
                i = html.index(after: i)
            }
        }
        
        // Add remaining text
        if !currentText.isEmpty {
            components.append(HTMLComponent(text: currentText, tags: Set(tagStack)))
        }
        
        return components
    }
}
