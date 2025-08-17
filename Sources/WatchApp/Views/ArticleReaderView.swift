import SwiftUI
import Foundation
#if canImport(AuthenticationServices)
import AuthenticationServices
#endif

// Lightweight, local web auth browser for watchOS; no-op on other platforms
@MainActor
final class WebAuthBrowser: ObservableObject {
#if os(watchOS) && canImport(AuthenticationServices)
    private var session: ASWebAuthenticationSession?
    func open(_ url: URL) {
        let session = ASWebAuthenticationSession(url: url, callbackURLScheme: nil) { [weak self] _, _ in
            self?.session = nil
        }
        session.prefersEphemeralWebBrowserSession = true
        self.session = session
        _ = session.start()
    }
#else
    func open(_ url: URL) { /* not supported */ }
#endif
}

struct ArticleReaderView: View {
    let url: URL
    @StateObject private var browser = WebAuthBrowser()
    @State private var didOpen = false

    var body: some View {
        VStack(spacing: 8) {
            ProgressView("Opening…")
            Button {
                browser.open(url)
            } label: {
                Label("Open Again", systemImage: "safari")
            }
            .buttonStyle(.bordered)
        }
        .navigationTitle("Article")
        .task {
            guard !didOpen else { return }
            didOpen = true
            browser.open(url)
        }
    }
}
