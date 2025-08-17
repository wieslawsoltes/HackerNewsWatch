import SwiftUI

@main
struct HackerNewsWatchApp: App {
    var body: some Scene {
        WindowGroup {
            FeedView()
                .tint(.orange)
        }
    }
}
