import SwiftUI
import WidgetKit

struct HNComplicationWidget: Widget {
    let kind: String = "HNComplicationWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ComplicationProvider()) { entry in
            ComplicationWidgetView(entry: entry)
        }
        .configurationDisplayName("HN Complication")
        .description("Shows Hacker News updates on your watch face")
        .supportedFamilies([
            .accessoryCorner,
            .accessoryCircular,
            .accessoryInline,
            .accessoryRectangular
        ])
    }
}

struct ComplicationEntry: TimelineEntry {
    let date: Date
    let story: HNStory
    let storyCount: Int
    let lastUpdated: Date
    
    static let placeholder = ComplicationEntry(
        date: Date(),
        story: HNStory(id: 1, title: "Sample Story", by: "user", url: nil, score: 100, time: nil, descendants: 25, kids: nil),
        storyCount: 42,
        lastUpdated: Date()
    )
}

struct ComplicationProvider: TimelineProvider {
    private let timelineProvider = HNTimelineProvider()
    
    func placeholder(in context: Context) -> ComplicationEntry {
        ComplicationEntry.placeholder
    }
    
    func getSnapshot(in context: Context, completion: @escaping (ComplicationEntry) -> Void) {
        let entry = ComplicationEntry(
            date: Date(),
            story: HNStory(
                id: 0,
                title: "Sample Story",
                url: nil,
                score: 100,
                by: "user",
                time: Int(Date().timeIntervalSince1970),
                descendants: 25,
                kids: []
            ),
            storyCount: 42,
            lastUpdated: Date()
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<ComplicationEntry>) -> Void) {
        timelineProvider.getTimeline(
            for: context,
            entryType: ComplicationEntry.self,
            in: context,
            completion: completion
        )
    }
}

struct ComplicationWidgetView: View {
    let entry: ComplicationEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .accessoryCorner:
            cornerView
        case .accessoryCircular:
            circularView
        case .accessoryInline:
            inlineView
        case .accessoryRectangular:
            rectangularView
        default:
            Text("HN")
        }
    }
    
    private var cornerView: some View {
        VStack {
            Image(systemName: "flame.fill")
                .foregroundStyle(.orange)
                .font(.title2)
            Text("\(entry.storyCount)")
                .font(.caption2)
                .fontWeight(.semibold)
        }
    }
    
    private var circularView: some View {
        VStack(spacing: 2) {
            Image(systemName: "flame.fill")
                .foregroundStyle(.orange)
                .font(.title3)
            Text("HN")
                .font(.caption2)
                .fontWeight(.bold)
            if let score = entry.story.score {
                Text("\(score)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var inlineView: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .foregroundStyle(.orange)
            Text(entry.story.title)
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }
    
    private var rectangularView: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                    .font(.caption)
                Text("Hacker News")
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(entry.storyCount)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Text(entry.story.title)
                .font(.caption2)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            HStack {
                if let score = entry.story.score {
                    HStack(spacing: 2) {
                        Image(systemName: "arrowtriangle.up.fill")
                            .foregroundStyle(.orange)
                            .font(.system(size: 8))
                        Text("\(score)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                if let descendants = entry.story.descendants {
                    HStack(spacing: 2) {
                        Image(systemName: "text.bubble")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 8))
                        Text("\(descendants)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(2)
    }
}