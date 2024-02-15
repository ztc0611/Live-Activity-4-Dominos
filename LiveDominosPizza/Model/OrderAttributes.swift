//
//  OrderAttributes.swift
//  LiveDominosPizza
//
//  Created by Zachary Coleman on 2/15/24.
//

import Foundation
import ActivityKit

public struct PizzaTrackerAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        public var minTime: Int
        public var maxTime: Int
      
      public init(minTime: Int, maxTime: Int) {
        self.minTime = minTime
        self.maxTime = maxTime
      }
  }
    
    public var startTime: String
    public var serviceMethod: String
    
    public init(StartTime: String, ServiceMethod: String) {
        self.startTime = StartTime
        self.serviceMethod = ServiceMethod
  }
}
