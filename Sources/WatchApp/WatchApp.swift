import SwiftUI
import WatchKit

@main
struct HackerNewsWatchApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                FeedView()
                    .tabItem {
                        Image(systemName: "list.bullet")
                        Text("Stories")
                    }
                
                FeedSelectorView()
                    .tabItem {
                        Image(systemName: "line.horizontal.3.decrease.circle")
                        Text("Feeds")
                    }
                
                SavedArticlesView()
                    .tabItem {
                        Image(systemName: "bookmark")
                        Text("Saved")
                    }
            }
        }
    }
}
