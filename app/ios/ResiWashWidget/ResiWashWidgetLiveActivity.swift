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
            let machineName = sharedDefault.string(forKey: context.attributes.prefixedKey("machineName")) ?? "Machine"
            let endDateString = sharedDefault.string(forKey: context.attributes.prefixedKey("endDate")) ?? "0"
            let startDateString = sharedDefault.string(forKey: context.attributes.prefixedKey("startDate")) ?? "0"
            let endDateDouble = Double(endDateString) ?? 0.0
            let startDateDouble = Double(startDateString) ?? 0.0
            
            let endDate = Date(timeIntervalSince1970: endDateDouble / 1000.0)
            let startDate = Date(timeIntervalSince1970: startDateDouble / 1000.0)
            let isFinishedExplicit = sharedDefault.bool(forKey: context.attributes.prefixedKey("isFinished"))
            let isFinished = isFinishedExplicit || Date() >= endDate

            let roomName = sharedDefault.string(forKey: context.attributes.prefixedKey("roomName")) ?? "Room"
            let headerText = machineName + " @ " + roomName + (isFinished ? " done!" : " running...")
            
            VStack {
                HStack {
                    Text(headerText)
                        .font(.headline)
                        .lineLimit(1)
                    Spacer()
                    if !isFinished {
                        Text(timerInterval: Date()...endDate, countsDown: true)
                            .font(.headline)
                            .multilineTextAlignment(.trailing)
                    }
                }
                .padding(.bottom, 4)
                
                if isFinished {
                    Text("Your machine is complete! Please collect ASAP.")
                        .font(.subheadline)
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ProgressView(timerInterval: startDate...endDate, countsDown: false)
                        .tint(.cyan)
                }
            }
            .padding(16)
            .foregroundColor(.white)
            .activityBackgroundTint(isFinished ? Color(red: 0x51/255.0, green: 0xCF/255.0, blue: 0x66/255.0) : Color(red: 0x51/255.0, green: 0x5B/255.0, blue: 0x92/255.0))
            .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            let machineName = sharedDefault.string(forKey: context.attributes.prefixedKey("machineName")) ?? "ResiWash"
            let roomName = sharedDefault.string(forKey: context.attributes.prefixedKey("roomName")) ?? "Room"
            let endDateString = sharedDefault.string(forKey: context.attributes.prefixedKey("endDate")) ?? "0"
            let startDateString = sharedDefault.string(forKey: context.attributes.prefixedKey("startDate")) ?? "0"
            let endDateDouble = Double(endDateString) ?? 0.0
            let startDateDouble = Double(startDateString) ?? 0.0
            let endDate = Date(timeIntervalSince1970: endDateDouble / 1000.0)
            let startDate = Date(timeIntervalSince1970: startDateDouble / 1000.0)
            let isFinishedExplicit = sharedDefault.bool(forKey: context.attributes.prefixedKey("isFinished"))
            let isFinished = isFinishedExplicit || Date() >= endDate

            let machineType = sharedDefault.string(forKey: context.attributes.prefixedKey("machineName"))

            let title = machineName + " @ " + roomName + (isFinished ? " done!" : " running...")

            return DynamicIsland {
                // Expanded UI goes here.
                DynamicIslandExpandedRegion(.leading) {
                    Text(title)
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if !isFinished {
                        Text(timerInterval: Date()...endDate, countsDown: true)
                            .font(.subheadline)
                            .multilineTextAlignment(.trailing)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if isFinished {
                        Text("Your machine is complete! Please collect ASAP")
                            .font(.subheadline)
                            .bold()
                            .foregroundColor(.green)
                            .padding(.top, 4)
                    } else {
                        ProgressView(timerInterval: startDate...endDate, countsDown: false)
                            .tint(.cyan)
                            .padding(.top, 4)
                    }
                }
            } compactLeading: {
                Image(systemName: isFinished ? "checkmark.circle.fill" : "washer")
                    .foregroundColor(isFinished ? .green : .cyan)
            } compactTrailing: {
                if !isFinished {
                
                    Text(timerInterval: Date()...endDate, countsDown: true)
                        .frame(maxWidth: 32)
                    
                } else {
                    Text("Done")
                        .foregroundColor(.green)
                }
            } minimal: {
                Image(systemName: isFinished ? "checkmark.circle.fill" : "washer")
                    .foregroundColor(isFinished ? .green : .cyan)
            }
            .widgetURL(URL(string: "resiwash://"))
            .keylineTint(Color.cyan)
        }
    }
}
