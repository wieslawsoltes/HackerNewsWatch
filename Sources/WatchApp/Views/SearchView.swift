import SwiftUI

struct SearchView: View {
    @StateObject private var vm = SearchViewModel()
    @StateObject private var savedArticlesManager = SavedArticlesManager.shared
    @FocusState private var isSearchFocused: Bool
    @State private var selectedUser: String?
    
    var body: some View {
        List {
            Section {
                HStack(alignment: .center, spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                        .imageScale(.medium)
                        .frame(width: 18, height: 18, alignment: .center)
                    TextField("Search Hacker News", text: $vm.query)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .onSubmit {
                            Task { await vm.search(reset: true) }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.body)
                        .focused($isSearchFocused)
                    
                    if !vm.query.isEmpty {
                        Button {
                            vm.query = ""
                            vm.results = []
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isSearchFocused = true
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                                .imageScale(.medium)
                                .frame(width: 18, height: 18, alignment: .center)
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .frame(minHeight: 36)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.regularMaterial)
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowPlatterColor(.clear)
            }
            
            if vm.isLoading && vm.results.isEmpty {
                HStack {
                    Spacer()
                    ProgressView("Searching…")
                    Spacer()
                }
                .listRowBackground(Color.clear)
            } else if let error = vm.error {
                Text("Error: \(error)")
                    .foregroundStyle(.red)
                    .listRowBackground(Color.clear)
            } else if vm.results.isEmpty && !vm.query.isEmpty {
                Text("No results")
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(vm.results) { story in
                    NavigationLink(value: story) {
                        StoryRow(
                            story: story,
                            savedArticlesManager: savedArticlesManager,
                            onUserSelected: { username in
                                selectedUser = username
                            }
                        )
                    }
                }
                if vm.canLoadMore {
                    if vm.isLoading {
                        HStack {
                            Spacer()
                            ProgressView().scaleEffect(0.8)
                            Spacer()
                        }
                        .listRowBackground(Color.clear)
                    } else {
                        Button("Load More") {
                            Task { await vm.loadMoreIfNeeded() }
                        }
                        .foregroundStyle(.orange)
                        .listRowBackground(Color.clear)
                    }
                }
            }
        }
        .listStyle(.carousel)
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: HNStory.self) { story in
            CommentsView(story: story)
        }
        .navigationDestination(item: $selectedUser) { username in
            UserDetailsView(username: username)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    Task { await vm.search(reset: true) }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(.orange)
                        .font(.title3)
                }
                .background(.regularMaterial, in: Circle())
                .buttonStyle(.plain)
                .disabled(vm.isLoading || vm.query.isEmpty)
            }
        }
        .onAppear {
            // Delay focusing to ensure the view is fully loaded
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isSearchFocused = true
            }
        }
    }
}

#Preview {
    SearchView()
}
