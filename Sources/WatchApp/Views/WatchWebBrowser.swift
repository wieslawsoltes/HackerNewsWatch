import Foundation
import SwiftUI
#if os(watchOS)
import AuthenticationServices

@MainActor
final class WatchWebBrowser: ObservableObject {
    private var session: ASWebAuthenticationSession?
    
    func open(_ url: URL) {
        let session = ASWebAuthenticationSession(url: url, callbackURLScheme: nil) { [weak self] _, _ in
            // Release when finished
            self?.session = nil
        }
        // Avoid the consent popup and cookie persistence; behaves like a lightweight web view.
        session.prefersEphemeralWebBrowserSession = true
        self.session = session
        _ = session.start()
    }
}
#endif
