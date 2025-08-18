import WidgetKit
import SwiftUI

@main
struct HNWidgetBundle: WidgetBundle {
    var body: some Widget {
        HNTopStoriesWidget()
        HNComplicationWidget()
    }
}