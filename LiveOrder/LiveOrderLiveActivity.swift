//
//  LiveOrderLiveActivity.swift
//  LiveOrder
//
//  Created by Zachary Coleman on 2/13/24.
//

import ActivityKit
import WidgetKit
import SwiftUI

let dateFormatter = ISO8601DateFormatter()

struct LiveOrderLiveActivity: Widget {
    var body: some WidgetConfiguration {
      ActivityConfiguration(for: PizzaTrackerAttributes.self) { context in
        // Lock screen
        HStack {
            VStack{
                Text(
                  timerInterval: Date.now...Date(timeInterval: TimeInterval(context.state.minTime * 60), since: dateFormatter.date(from: context.attributes.startTime) ?? .now)
                )
                Text("Minimum").foregroundColor(.cyan)
            }
            .multilineTextAlignment(.center)
            VStack{
                Text(
                  timerInterval: Date.now...Date(timeInterval: TimeInterval(context.state.maxTime * 60), since: dateFormatter.date(from: context.attributes.startTime) ?? .now)
                )
                Text("Maximum").foregroundColor(.red)
            }
            .multilineTextAlignment(.center)
          }
          .padding()
          //.activityBackgroundTint(<#T##color: Color?##Color?#>)
      } dynamicIsland: { context in
        DynamicIsland {
          DynamicIslandExpandedRegion(.leading) {
            VStack{
              Text(
                timerInterval: Date.now...Date(timeInterval: TimeInterval(context.state.minTime * 60), since: dateFormatter.date(from: context.attributes.startTime) ?? .now)
              )
              .multilineTextAlignment(.center)
              .foregroundColor(.cyan)
              Text("Minimum")
            }
          }
          DynamicIslandExpandedRegion(.trailing) {
            VStack{
              Text(
                timerInterval: Date.now...Date(timeInterval: TimeInterval(context.state.maxTime * 60), since: dateFormatter.date(from: context.attributes.startTime) ?? .now)
              )
              .multilineTextAlignment(.center)
              .foregroundColor(.red)
              Text("Maximum")
            }
          }
          DynamicIslandExpandedRegion(.bottom) {
            HStack{
              Image(systemName: "timer")
                Text("\(context.attributes.serviceMethod) in Progress")
            }
          }
        } compactLeading: {
          Text(
            timerInterval: Date.now...Date(timeInterval: TimeInterval(context.state.minTime * 60), since: dateFormatter.date(from: context.attributes.startTime) ?? .now)
          )
          .multilineTextAlignment(.center)
          .frame(maxWidth: 48)
          .minimumScaleFactor(0.45)
          .foregroundColor(.cyan)
        } compactTrailing: {
          Text(
            timerInterval: Date.now...Date(timeInterval: TimeInterval(context.state.maxTime * 60), since: dateFormatter.date(from: context.attributes.startTime) ?? .now)
          )
          .multilineTextAlignment(.center)
          .frame(maxWidth: 48)
          .minimumScaleFactor(0.45)
          .foregroundColor(.red)
        } minimal: {
          Text(
              "~\(timerInterval: Date.now...Date(timeInterval: TimeInterval((context.state.maxTime+context.state.minTime)/2 * 60), since: dateFormatter.date(from: context.attributes.startTime) ?? .now), showsHours: false)"
          )
          .multilineTextAlignment(.center)
          .minimumScaleFactor(0.45)
          .foregroundColor(.purple)
        }
      }
    }
  }
