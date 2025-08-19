import SwiftUI
import WatchKit

struct CommentsView: View {
    let story: HNStory
    @StateObject private var vm = CommentsViewModel.shared
    @State private var crownValue: Double = 0
    @State private var selectedCommentIndex: Int = 0
    
    var body: some View {
        List {
            // Story details section
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(story.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(nil)
                    
                    HStack(spacing: 12) {
                        if let by = story.by {
                            NavigationLink(value: by) {
                                Image(systemName: "person.circle")
                                    .foregroundStyle(.orange)
                                    .font(.caption)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        if let score = story.score {
                            HStack(spacing: 2) {
                                Image(systemName: "arrowtriangle.up.fill")
                                    .foregroundStyle(.orange)
                                    .font(.caption2)
                                Text("\(score)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        if let time = story.time {
                            HStack(spacing: 2) {
                                Image(systemName: "clock")
                                    .foregroundStyle(.secondary)
                                    .font(.caption2)
                                Text(formatTimeAgo(time))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    if let url = story.url, let linkURL = URL(string: url) {
                        NavigationLink(value: linkURL) {
                            Label("Open Article", systemImage: "doc.text.magnifyingglass")
                                .foregroundStyle(.orange)
                                .font(.subheadline)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            if let root = vm.root {
                CommentTree(node: root, viewModel: vm)
            } else if vm.isLoading {
                VStack(spacing: 8) {
                    ProgressView("Loading comments…")
                        .font(.caption)
                    if vm.loadingProgress > 0 {
                        VStack(spacing: 4) {
                            ProgressView(value: vm.loadingProgress)
                                .progressViewStyle(LinearProgressViewStyle())
                                .scaleEffect(0.8)
                            Text("\(Int(vm.loadingProgress * 100))%")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .listRowBackground(Color.clear)
                .padding(.vertical, 8)
            } else if let error = vm.error {
                Text("Error: \(error)")
            }
        }
        .scrollBounceBehavior(.always)
        .refreshable {
            await vm.load(for: story, forceReload: true)
        }
        .focusable()
        .digitalCrownRotation(
            $crownValue,
            from: 0,
            through: Double(max(0, (vm.root?.children.count ?? 1) - 1)),
            by: 1,
            sensitivity: .medium,
            isContinuous: false,
            isHapticFeedbackEnabled: true
        )
        .onChange(of: crownValue) { _, newValue in
            let newIndex = Int(newValue.rounded())
            let maxComments = vm.root?.children.count ?? 0
            let maxIndex = max(0, maxComments - 1)
            let clampedIndex = min(max(0, newIndex), maxIndex)
            
            if clampedIndex != selectedCommentIndex && clampedIndex < maxComments {
                selectedCommentIndex = clampedIndex
                WKInterfaceDevice.current().play(.click)
            }
        }
        .navigationTitle("Comments")
        .navigationDestination(for: URL.self) { url in
            ArticleReaderView(url: url)
        }
        .navigationDestination(for: String.self) { username in
            UserDetailsView(username: username)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    Task { await vm.load(for: story, forceReload: true) }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(.orange)
                        .font(.title3)
                }
                .background(.regularMaterial, in: Circle())
                .buttonStyle(.plain)
                .disabled(vm.isLoading)
            }
        }
        .onAppear {
            Task {
                await vm.load(for: story)
            }
            // Reset crown state when view appears
            resetCrownState()
        }
        .onDisappear {
            // Reset crown state when leaving comments view
            // This ensures clean state when returning to feed
            crownValue = 0
            selectedCommentIndex = 0
        }
    }
    
    private func resetCrownState() {
        // Reset crown value to current selected comment index to maintain consistency
        crownValue = Double(selectedCommentIndex)
        
        // Ensure selected index is within bounds
        let maxComments = vm.root?.children.count ?? 0
        if selectedCommentIndex >= maxComments {
            selectedCommentIndex = max(0, maxComments - 1)
            crownValue = Double(selectedCommentIndex)
        }
    }
    
    private func formatTimeAgo(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let now = Date()
        let interval = now.timeIntervalSince(date)
        
        let minutes = Int(interval / 60)
        let hours = Int(interval / 3600)
        let days = Int(interval / 86400)
        
        if days > 0 {
            return "\(days)d ago"
        } else if hours > 0 {
            return "\(hours)h ago"
        } else if minutes > 0 {
            return "\(minutes)m ago"
        } else {
            return "now"
        }
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
                            NavigationLink(value: by) {
                                HStack(spacing: 2) {
                                    Image(systemName: "person.circle")
                                        .foregroundStyle(.orange)
                                    Text(by)
                                        .font(.caption2)
                                        .foregroundStyle(.orange)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        Spacer()
                        if hasChildren {
                            Button(action: toggleExpansion) {
                                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                            }
                            .background(.regularMaterial, in: Circle())
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    CommentTextView(htmlComponents: cleanHTML(node.comment.text ?? "[no text]"))
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
}

struct HTMLComponent {
    let text: String
    let tags: Set<String>
    let url: String?
    
    init(text: String, tags: Set<String>, url: String? = nil) {
        self.text = text
        self.tags = tags
        self.url = url
    }
}

struct CommentTextView: View {
    let htmlComponents: [HTMLComponent]
    @StateObject private var browser = WebAuthBrowser()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(Array(htmlComponents.enumerated()), id: \.offset) { index, component in
                if component.tags.contains("a"), let urlString = component.url, let url = URL(string: urlString) {
                    Button(action: {
                        browser.open(url)
                    }) {
                        Text(component.text)
                            .foregroundColor(.orange)
                            .underline()
                            .font(.footnote)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    Text(formatComponent(component))
                        .font(.footnote)
                }
            }
        }
    }
    
    private func formatComponent(_ component: HTMLComponent) -> AttributedString {
        var attributedString = AttributedString(component.text)
        
        // Apply formatting based on tags
        if component.tags.contains("i") || component.tags.contains("em") {
            attributedString.font = .footnote.italic()
        }
        if component.tags.contains("b") || component.tags.contains("strong") {
            attributedString.font = .footnote.bold()
        }
        if component.tags.contains("code") {
            attributedString.font = .footnote.monospaced()
            attributedString.backgroundColor = Color.gray.opacity(0.2)
        }
        
        return attributedString
    }
}

extension CommentNodeView {
    private func cleanHTML(_ html: String) -> [HTMLComponent] {
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
        return parseHTMLComponents(text)
    }
    
    private func parseHTMLComponents(_ html: String) -> [HTMLComponent] {
        var components: [HTMLComponent] = []
        var currentText = ""
        var tagStack: [String] = []
        var urlStack: [String?] = []
        var i = html.startIndex
        
        while i < html.endIndex {
            if html[i] == "<" {
                // Save current text if any
                if !currentText.isEmpty {
                    let currentURL = urlStack.last ?? nil
                    components.append(HTMLComponent(text: currentText, tags: Set(tagStack), url: currentURL))
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
                        if tagName == "a" && !urlStack.isEmpty {
                            urlStack.removeLast()
                        }
                    }
                } else {
                    // Add to stack (ignore self-closing tags like <br/>)
                    if !tagContent.hasSuffix("/") && !["br", "hr", "img"].contains(tagName) {
                        tagStack.append(tagName)
                        
                        // Extract URL from <a> tags
                        if tagName == "a" {
                            let extractedURL = extractHrefFromTag(tagContent)
                            urlStack.append(extractedURL)
                        } else {
                            urlStack.append(urlStack.last ?? nil)
                        }
                    }
                    
                    // Handle special cases
                    if tagName == "br" {
                        let currentURL = urlStack.last ?? nil
                        components.append(HTMLComponent(text: "\n", tags: Set(tagStack), url: currentURL))
                    } else if tagName == "p" && !components.isEmpty {
                        let currentURL = urlStack.last ?? nil
                        components.append(HTMLComponent(text: "\n\n", tags: Set(tagStack), url: currentURL))
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
            let currentURL = urlStack.last ?? nil
            components.append(HTMLComponent(text: currentText, tags: Set(tagStack), url: currentURL))
        }
        
        return components
    }
    
    private func extractHrefFromTag(_ tagContent: String) -> String? {
        // Look for href="..." or href='...'
        let patterns = [
            #"href\s*=\s*"([^"]*)"#,
            #"href\s*=\s*'([^']*)'"#,
            #"href\s*=\s*([^\s>]+)"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: tagContent, options: [], range: NSRange(location: 0, length: tagContent.count)),
               let range = Range(match.range(at: 1), in: tagContent) {
                return String(tagContent[range])
            }
        }
        
        return nil
    }
}
