import SwiftUI

@main
struct HackerNewsWatchApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                FeedView()
                    .tabItem {
                        Image(systemName: "list.bullet")
                        Text("Feed")
                    }
                
                FeedSelectorView()
                    .tabItem {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        Text("Feeds")
                    }
                
                SavedArticlesView()
                    .tabItem {
                        Image(systemName: "bookmark.fill")
                        Text("Saved")
                    }
            }
            .tint(.orange)
        }
    }
}
