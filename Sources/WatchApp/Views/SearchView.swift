import SwiftUI

struct SearchView: View {
    @StateObject private var vm = SearchViewModel()
    @StateObject private var savedArticlesManager = SavedArticlesManager.shared
    @FocusState private var isSearchFocused: Bool
    @State private var selectedUser: String?
    
    var body: some View {
        List {
            Section {
                TextField(
                    "",
                    text: $vm.query,
                    prompt: Text("Search Hacker News")
                        .foregroundStyle(.secondary)
                )
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .onSubmit {
                    Task { await vm.search(reset: true) }
                }
                .padding(.leading, 34)
                .padding(.trailing, vm.query.isEmpty ? 16 : 50)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .font(.body)
                .focused($isSearchFocused)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.regularMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(.white.opacity(0.1), lineWidth: 0.5)
                )
                .overlay(alignment: .leading) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                        .imageScale(.medium)
                        .frame(width: 20, height: 20)
                        .padding(.leading, 12)
                        .padding(.trailing, 4)
                }
                .overlay(alignment: .trailing) {
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
                                .frame(width: 20, height: 20)
                                .padding(6)
                                .background(.thinMaterial, in: Circle())
                        }
                        .padding(.trailing, 10)
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                    }
                }
                .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .listRowInsets(EdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14))
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
