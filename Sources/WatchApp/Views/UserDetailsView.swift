import SwiftUI
import Foundation

struct UserDetailsView: View {
    let username: String
    @State private var user: HNUser?
    @State private var isLoading = false
    @State private var error: String?
    
    private let service = HNService()
    
    var body: some View {
        List {
            if let user = user {
                UserInfoSection(user: user)
            } else if isLoading {
                ProgressView("Loading user...")
                    .listRowBackground(Color.clear)
                    .padding(.vertical, 8)
            } else if let error = error {
                Text("Error: \(error)")
                    .foregroundStyle(.red)
            }
        }
        .navigationTitle(username)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await loadUser()
        }
        .onAppear {
            Task {
                await loadUser()
            }
        }
    }
    
    private func loadUser() async {
        isLoading = true
        error = nil
        
        do {
            let fetchedUser = try await service.user(username)
            await MainActor.run {
                self.user = fetchedUser
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}

struct UserInfoSection: View {
    let user: HNUser
    
    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                // User ID
                HStack {
                    Image(systemName: "person.circle.fill")
                        .foregroundStyle(.orange)
                    Text(user.id)
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                
                // Karma
                if let karma = user.karma {
                    HStack {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundStyle(.orange)
                        Text("Karma: \(karma)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Member since
                if let created = user.created {
                    HStack {
                        Image(systemName: "calendar.circle.fill")
                            .foregroundStyle(.orange)
                        Text("Member since: \(formatDate(created))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Submissions count
                if let submitted = user.submitted {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundStyle(.orange)
                        Text("Submissions: \(submitted.count)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        
        // About section
        if let about = user.about, !about.isEmpty {
            Section("About") {
                Text(cleanHTMLText(about))
                    .font(.footnote)
                    .foregroundStyle(.primary)
                    .padding(.vertical, 4)
            }
        }
    }
    
    private func formatDate(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func cleanHTMLText(_ html: String) -> String {
        // Basic HTML cleaning - remove common tags
        return html
            .replacingOccurrences(of: "<p>", with: "\n\n")
            .replacingOccurrences(of: "</p>", with: "")
            .replacingOccurrences(of: "<br>", with: "\n")
            .replacingOccurrences(of: "<br/>", with: "\n")
            .replacingOccurrences(of: "<br />", with: "\n")
            .replacingOccurrences(of: "&#x27;", with: "'")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

#Preview {
    NavigationView {
        UserDetailsView(username: "pg")
    }
}