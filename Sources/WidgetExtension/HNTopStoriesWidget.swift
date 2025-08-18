import SwiftUI
import WidgetKit

struct HNTopStoriesWidget: Widget {
    let kind: String = "HNTopStoriesWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TopStoriesProvider()) { entry in
            TopStoriesWidgetView(entry: entry)
        }
        .configurationDisplayName("Top Stories")
        .description("Shows the latest top stories from Hacker News")
        .supportedFamilies([.accessoryRectangular, .accessoryInline, .accessoryCircular])
    }
}

struct TopStoriesEntry: TimelineEntry {
    let date: Date
    let stories: [HNStory]
    let lastUpdated: Date
    
    static let placeholder = TopStoriesEntry(
        date: Date(),
        stories: [
            HNStory(id: 1, title: "Sample Story Title", by: "user", url: nil, score: 100, time: nil, descendants: 50, kids: nil)
        ],
        lastUpdated: Date()
    )
}

struct TopStoriesProvider: TimelineProvider {
    private let timelineProvider = HNTimelineProvider()
    
    func placeholder(in context: Context) -> TopStoriesEntry {
        TopStoriesEntry(
            date: Date(),
            stories: [],
            lastUpdated: Date()
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (TopStoriesEntry) -> Void) {
        let entry = TopStoriesEntry(
            date: Date(),
            stories: [],
            lastUpdated: Date()
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TopStoriesEntry>) -> Void) {
        timelineProvider.getTimeline(
            for: context,
            entryType: TopStoriesEntry.self,
            in: context,
            completion: completion
        )
    }
}

struct TopStoriesWidgetView: View {
    let entry: TopStoriesEntry
    
    var body: some View {
        switch entry.stories.count {
        case 0:
            Text("No Stories")
                .font(.caption2)
                .foregroundStyle(.secondary)
        case 1:
            singleStoryView
        default:
            multipleStoriesView
        }
    }
    
    private var singleStoryView: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                    .font(.caption2)
                Text("HN")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.orange)
                Spacer()
            }
            
            Text(entry.stories[0].title)
                .font(.caption2)
                .fontWeight(.medium)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            
            if let score = entry.stories[0].score {
                HStack {
                    Image(systemName: "arrowtriangle.up.fill")
                        .foregroundStyle(.orange)
                        .font(.system(size: 8))
                    Text("\(score)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
        }
        .padding(4)
    }
    
    private var multipleStoriesView: some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                    .font(.caption2)
                Text("Top Stories")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.orange)
                Spacer()
            }
            
            ForEach(Array(entry.stories.prefix(3).enumerated()), id: \.element.id) { index, story in
                HStack {
                    Text("\(index + 1).")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: 12, alignment: .leading)
                    
                    Text(story.title)
                        .font(.caption2)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    Spacer()
                    
                    if let score = story.score {
                        Text("\(score)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(4)
    }
}