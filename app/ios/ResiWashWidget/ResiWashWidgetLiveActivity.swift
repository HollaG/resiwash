import ActivityKit
import WidgetKit
import SwiftUI

struct LiveActivitiesAppAttributes: ActivityAttributes, Identifiable {
    public typealias LiveDeliveryData = ContentState
    public struct ContentState: Codable, Hashable {}
    var id = UUID()
}

extension LiveActivitiesAppAttributes {
    func prefixedKey(_ key: String) -> String {
        return "\(id)_\(key)"
    }
}

let sharedDefault = UserDefaults(suiteName: "group.com.resiwash.app")!

struct ResiWashWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveActivitiesAppAttributes.self) { context in
            // Lock screen/banner UI goes here
            let machineName = sharedDefault.string(forKey: context.attributes.prefixedKey("machineName")) ?? "ResiWash"
            let endDateString = sharedDefault.string(forKey: context.attributes.prefixedKey("endDate")) ?? "0"
            let startDateString = sharedDefault.string(forKey: context.attributes.prefixedKey("startDate")) ?? "0"
            let endDateDouble = Double(endDateString) ?? 0.0
            let startDateDouble = Double(startDateString) ?? 0.0
            
            let endDate = Date(timeIntervalSince1970: endDateDouble / 1000.0)
            let startDate = Date(timeIntervalSince1970: startDateDouble / 1000.0)
            
            VStack {
                HStack {
                    Text(machineName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Text(timerInterval: Date()...endDate, countsDown: true)
                        .font(.headline)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.primary)
                }
                .padding(.bottom, 4)
                
                ProgressView(timerInterval: startDate...endDate, countsDown: false)
                    .tint(.cyan)
            }
            .padding(16)

        } dynamicIsland: { context in
            let machineName = sharedDefault.string(forKey: context.attributes.prefixedKey("machineName")) ?? "ResiWash"
            let endDateString = sharedDefault.string(forKey: context.attributes.prefixedKey("endDate")) ?? "0"
            let startDateString = sharedDefault.string(forKey: context.attributes.prefixedKey("startDate")) ?? "0"
            let endDateDouble = Double(endDateString) ?? 0.0
            let startDateDouble = Double(startDateString) ?? 0.0
            let endDate = Date(timeIntervalSince1970: endDateDouble / 1000.0)
            let startDate = Date(timeIntervalSince1970: startDateDouble / 1000.0)

            return DynamicIsland {
                // Expanded UI goes here.
                DynamicIslandExpandedRegion(.leading) {
                    Text(machineName)
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: Date()...endDate, countsDown: true)
                        .font(.subheadline)
                        .multilineTextAlignment(.trailing)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(timerInterval: startDate...endDate, countsDown: false)
                        .tint(.cyan)
                        .padding(.top, 4)
                }
            } compactLeading: {
                Image(systemName: "washer")
                    .foregroundColor(.cyan)
            } compactTrailing: {
                Text(timerInterval: Date()...endDate, countsDown: true)
                    .frame(maxWidth: 32)
            } minimal: {
                Image(systemName: "washer")
                    .foregroundColor(.cyan)
            }
            .widgetURL(URL(string: "resiwash://"))
            .keylineTint(Color.cyan)
        }
    }
}
