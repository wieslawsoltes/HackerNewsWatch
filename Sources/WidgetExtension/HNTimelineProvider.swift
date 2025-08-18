import Foundation
import WidgetKit

struct HNTimelineProvider {
    private let service = HNService()
    
    func getTimeline<T: TimelineEntry>(
        for configuration: Any,
        entryType: T.Type,
        in context: TimelineProviderContext,
        completion: @escaping (Timeline<T>) -> Void
    ) {
        Task {
            do {
                let entries = try await createEntries(for: entryType, context: context)
                let timeline = Timeline(
                    entries: entries,
                    policy: .after(Date().addingTimeInterval(15 * 60)) // Refresh every 15 minutes
                )
                completion(timeline)
            } catch {
                // Fallback to placeholder entry on error
                let placeholderEntry = createPlaceholderEntry(for: entryType)
                let timeline = Timeline(
                    entries: [placeholderEntry],
                    policy: .after(Date().addingTimeInterval(5 * 60)) // Retry in 5 minutes
                )
                completion(timeline)
            }
        }
    }
    
    private func createEntries<T: TimelineEntry>(
        for entryType: T.Type,
        context: TimelineProviderContext
    ) async throws -> [T] {
        let now = Date()
        var entries: [T] = []
        
        // Create entries for the next hour with 15-minute intervals
        for minuteOffset in stride(from: 0, to: 60, by: 15) {
            let entryDate = now.addingTimeInterval(TimeInterval(minuteOffset * 60))
            
            if entryType == TopStoriesEntry.self {
                let entry = try await createTopStoriesEntry(for: entryDate) as! T
                entries.append(entry)
            } else if entryType == ComplicationEntry.self {
                let entry = try await createComplicationEntry(for: entryDate) as! T
                entries.append(entry)
            }
        }
        
        return entries
    }
    
    private func createTopStoriesEntry(for date: Date) async throws -> TopStoriesEntry {
        let storyIDs = try await service.storyIDs(for: .top)
        let topStoryIDs = Array(storyIDs.prefix(5))
        
        var stories: [HNStory] = []
        for id in topStoryIDs {
            if let story = try? await service.story(id: id) {
                stories.append(story)
            }
        }
        
        return TopStoriesEntry(
            date: date,
            stories: stories,
            lastUpdated: Date()
        )
    }
    
    private func createComplicationEntry(for date: Date) async throws -> ComplicationEntry {
        let storyIDs = try await service.storyIDs(for: .top)
        let topStory = try await service.story(id: storyIDs[0])
        
        return ComplicationEntry(
            date: date,
            story: topStory,
            storyCount: min(storyIDs.count, 99), // Limit to 99 for display
            lastUpdated: Date()
        )
    }
    
    private func createPlaceholderEntry<T: TimelineEntry>(for entryType: T.Type) -> T {
        let now = Date()
        
        if entryType == TopStoriesEntry.self {
            return TopStoriesEntry(
                date: now,
                stories: [],
                lastUpdated: now
            ) as! T
        } else if entryType == ComplicationEntry.self {
            let placeholderStory = HNStory(
                id: 0,
                title: "Loading...",
                url: nil,
                score: 0,
                by: "user",
                time: Int(now.timeIntervalSince1970),
                descendants: 0,
                kids: []
            )
            return ComplicationEntry(
                date: now,
                story: placeholderStory,
                storyCount: 0,
                lastUpdated: now
            ) as! T
        }
        
        fatalError("Unsupported entry type")
    }
}

// MARK: - Live Data Support
extension HNTimelineProvider {
    func enableLiveUpdates() {
        // Live updates would be handled by the timeline refresh policy
        // Widgets will automatically refresh based on the timeline policy
    }
    
    func disableLiveUpdates() {
        // No action needed as we're not using real-time observers
    }
    
    private func refreshWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}