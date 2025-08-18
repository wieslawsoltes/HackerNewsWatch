import SwiftUI

struct FeedSelectorView: View {
    @StateObject private var feedViewModel = FeedViewModel.shared
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(FeedType.allCases, id: \.self) { feedType in
                    Button(action: {
                        Task {
                            await feedViewModel.changeFeed(to: feedType)
                        }
                    }) {
                        HStack {
                            Image(systemName: feedType.systemImage)
                                .foregroundStyle(.orange)
                                .font(.title2)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(feedType.displayName)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                
                                Text(feedDescription(for: feedType))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            if feedViewModel.feedType == feedType {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.orange)
                                    .font(.caption)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .listStyle(.plain)
            .navigationTitle("Select Feed")
        }
    }
    
    private func feedDescription(for feedType: FeedType) -> String {
        switch feedType {
        case .top:
            return "Most popular stories"
        case .new:
            return "Latest submissions"
        case .best:
            return "Highest rated stories"
        case .ask:
            return "Questions from the community"
        case .show:
            return "Show and tell posts"
        case .job:
            return "Job postings"
        }
    }
}

#Preview {
    FeedSelectorView()
}