//
//  ContentView.swift
//  LiveDominosPizza
//
//  Created by Zachary Coleman on 2/13/24.
//

import SwiftUI
import Combine
import BackgroundTasks
import ActivityKit

let dateFormatter = ISO8601DateFormatter()

struct ContentView: View {
    @State public var phoneNumber: String = ""
    @StateObject private var activityHelper = ActivityHelper()
    @State private var selectedTab: Tab = .tracker
    
    enum Tab {
        case tracker
        case debug
    }
  
    var body: some View {
        TabView(selection: $selectedTab) {
            TrackerView(phoneNumber: $phoneNumber, activityHelper: activityHelper)
                .tabItem {
                    Label("Tracker", systemImage: "location.north.fill")
                }
                .tag(Tab.tracker)
            
            DebugView(activityHelper: activityHelper)
                .tabItem {
                    Label("Debug", systemImage: "ant.circle")
                }
                .tag(Tab.debug)
        }
    }
}

struct TrackerView: View {
    @Binding var phoneNumber: String
    @ObservedObject var activityHelper: ActivityHelper
    @State private var isKeyboardVisible = false
    @State private var activityStarted = false // live activity has started
    @State private var showError = false
    
    var body: some View {
        VStack {
            Text("Live Activity Pizza Tracker for Dominos")
                .font(.title)
                .padding()
                .padding(.top)
            
            TextField("Enter Phone Number", text: $phoneNumber)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.phonePad)
                .padding()
                .textContentType(.telephoneNumber)
                .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                    isKeyboardVisible = true
                }
                .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                    isKeyboardVisible = false
                }
            
            Button(action: {
                activityHelper.performFirstAPIRequest(with: phoneNumber)
            }) {
                Text("Start")
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding()
            .disabled(phoneNumber.count != 10) // Disable button if phone number is not 10 digits
            .opacity(phoneNumber.count != 10 ? 0.6 : 1.0) // Reduce opacity when disabled
            
            if showError {
                Text("Error. Try Again?")
                    .foregroundColor(.red)
                    .padding()
            } else if activityStarted {
                Text("Live activity has started!")
                    .foregroundColor(.green)
                    .padding()
            }
            
            Spacer()
        }
        .padding()
        .onTapGesture {
            if isKeyboardVisible {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
        .onReceive(activityHelper.$result) { result in
            if result.contains("Error") {
                showError = true
            }
        }
        .onReceive(activityHelper.$minWaitTime.combineLatest(activityHelper.$maxWaitTime)) { minWaitTime, maxWaitTime in
            if minWaitTime != 0 && maxWaitTime != 0 {
                activityStarted = true // Update the state when both requests succeed
            }
        }
    }
}

struct DebugView: View {
    @ObservedObject var activityHelper: ActivityHelper
    
    var body: some View {
        List {
            Text("Service Method: \(activityHelper.serviceMethod)")
            Text("Pickup/Delivery: \(activityHelper.serviceMethodType)")
            Text("Estimated Wait Time: \(activityHelper.minWaitTime)-\(activityHelper.maxWaitTime) minutes")
            Text("Start Time: \(activityHelper.startTime)")
        }
        .listStyle(GroupedListStyle())
        .navigationBarTitle("Debug")
    }
}

final class ActivityHelper: ObservableObject {
    @MainActor @Published private(set) var activityID: String?
    @Published public var result: String = ""
    @Published public var serviceMethod: String = ""
    @Published public var minWaitTime: Int = 0
    @Published public var maxWaitTime: Int = 0
    @Published public var startTime: String = ""
    @Published public var serviceMethodType: String = ""

    func performFirstAPIRequest(with phoneNumber: String) {
    guard let url = URL(string: "https://tracker.dominos.com/tracker-presentation-service/v2/orders?phonenumber=\(phoneNumber)") else {
      result = "Invalid URL"
      return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
    request.setValue("en", forHTTPHeaderField: "dpz-language")
    request.setValue("UNITED_STATES", forHTTPHeaderField: "dpz-market")

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
      guard let data = data, error == nil else {
        self.result = "Error: \(error?.localizedDescription ?? "Unknown error")"
        return
      }
      
      do {
        let decoder = JSONDecoder()
        let trackingDataArray = try decoder.decode([TrackingData].self, from: data)
        guard let trackingData = trackingDataArray.first else {
          self.result = "Error: No tracking data found"
          return
        }
        
        DispatchQueue.main.async {
          self.serviceMethod = trackingData.orderDescription
          self.startTime = trackingData.orderTakeCompleteTime
          self.result = "First Request Successful"
          self.performSecondAPIRequest(trackingData.actions.track) // pass the track URL
        }
        
      } catch {
        self.result = "Error parsing JSON: \(error.localizedDescription)"
      }
    }

    task.resume()
  }
  
    func performSecondAPIRequest(_ trackURL: String) {
        let fullURL = "https://tracker.dominos.com/tracker-presentation-service\(trackURL)"
        guard let url = URL(string: fullURL) else {
            print("Invalid Second URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("en", forHTTPHeaderField: "dpz-language")
        request.setValue("UNITED_STATES", forHTTPHeaderField: "dpz-market")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error in Second API Request: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Second API Response Status Code: \(httpResponse.statusCode)")
            }
            
            do {
                let decoder = JSONDecoder()
                let estimatedWait = try decoder.decode(PizzaTrackingData.self, from: data)
                DispatchQueue.main.async {
                    self.startTime = estimatedWait.startTime
                    self.serviceMethodType = estimatedWait.serviceMethod
                    let estimatedWaitArray = estimatedWait.estimatedWaitMinutes.components(separatedBy: "-")
                    if estimatedWaitArray.count == 2, let min = Int(estimatedWaitArray[0]), let max = Int(estimatedWaitArray[1]) {
                        self.minWaitTime = min
                        self.maxWaitTime = max
                        self.result = "Second Request Successful"
                        self.startNewLiveActivity() // Call startNewLiveActivity() after updating minWaitTime and maxWaitTime
                    } else {
                        self.result = "Error: Estimated wait time format is incorrect"
                    }
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.result = "Error parsing JSON: \(error.localizedDescription)"
                }
            }
        }
        
        task.resume()
    }
  
    func startNewLiveActivity() {
        print("starting....")
        Task {
            let content = PizzaTrackerAttributes.ContentState(
                minTime: minWaitTime,
                maxTime: maxWaitTime
            )
            
            let staleDate = Date.distantFuture
            print(staleDate)
            
            // Schedule the activity
            let activity = try? Activity.request(
                attributes: PizzaTrackerAttributes(
                    StartTime: startTime,
                    ServiceMethod: serviceMethodType
                ),
                content: ActivityContent(
                    state: content,
                    staleDate: staleDate,
                    relevanceScore: 100
                )
            )
            
            if let activity = activity {
                        print("Activity requested successfully with ID:", activity.id)
                    } else {
                        print("Failed to request activity.")
                    }
            
            await MainActor.run { activityID = activity?.id }
        }
    }
    
    func endActivity() { //TODO: Fix this. Doesn't dismiss automatically like it should.
      Task {
        guard let activityID = await activityID,
              let runningActivity = Activity<PizzaTrackerAttributes>.activities.first(where: { $0.id == activityID }) else {
          return
        }
        
        let endContent = PizzaTrackerAttributes.ContentState(
          minTime: 0,
          maxTime: 0
        )
        
        await runningActivity.end(
          ActivityContent(state: endContent, staleDate: Date.distantFuture),
          dismissalPolicy: .after(Date(timeInterval: TimeInterval(maxWaitTime * 60), since: dateFormatter.date(from: startTime) ?? .now))
        )

        await MainActor.run { self.activityID = nil }
      }

    }
}

struct TrackingData: Decodable {
    let storeID: String
    let orderID: String
    let orderDescription: String
    let orderTakeCompleteTime: String
    let actions: ActionsData
    
    enum CodingKeys: String, CodingKey {
        case storeID = "StoreID"
        case orderID = "OrderID"
        case orderDescription = "OrderDescription"
        case orderTakeCompleteTime = "OrderTakeCompleteTime"
        case actions = "Actions"
    }
}

struct PizzaTrackingData: Decodable {
    let storeAsOfTime: String
    let storeID: String
    let orderID: String
    let pulseOrderGuid: String
    let phone: String
    let serviceMethod: String
    let orderDescription: String
    let productCategories: [String]
    let orderTakeCompleteTime: String
    let takeTimeSecs: Int
    let csrID: String
    let orderSourceCode: String
    let orderStatus: String
    let startTime: String
    let orderKey: String
    let managerID: String
    let managerName: String
    let deliveryLocation: [String: String]?
    let deliveryHotspot: [String: String]?
    let estimatedWaitMinutes: String
    let metaData: MetaData
    
    // Additional properties for delivery
    let deliveryAddress: String? // Optional for delivery
    let deliveryTime: String? // Optional for delivery
    
    enum CodingKeys: String, CodingKey {
        case storeAsOfTime = "StoreAsOfTime"
        case storeID = "StoreID"
        case orderID = "OrderID"
        case pulseOrderGuid = "PulseOrderGuid"
        case phone = "Phone"
        case serviceMethod = "ServiceMethod"
        case orderDescription = "OrderDescription"
        case productCategories = "ProductCategories"
        case orderTakeCompleteTime = "OrderTakeCompleteTime"
        case takeTimeSecs = "TakeTimeSecs"
        case csrID = "CsrID"
        case orderSourceCode = "OrderSourceCode"
        case orderStatus = "OrderStatus"
        case startTime = "StartTime"
        case orderKey = "OrderKey"
        case managerID = "ManagerID"
        case managerName = "ManagerName"
        case deliveryLocation = "DeliveryLocation"
        case deliveryHotspot = "DeliveryHotspot"
        case estimatedWaitMinutes = "EstimatedWaitMinutes"
        case metaData = "metaData"
        
        // Additional coding keys for delivery properties
        case deliveryAddress = "DeliveryAddress"
        case deliveryTime = "DeliveryTime"
    }
}


struct MetaData: Decodable {
    let surpriseFreeAwarded: Bool
    let dtmOrder: Bool
    let piePassPickup: Bool
    
    enum CodingKeys: String, CodingKey {
        case surpriseFreeAwarded = "surpriseFreeAwarded"
        case dtmOrder = "dtmOrder"
        case piePassPickup = "PiePassPickup"
    }
}


struct ActionsData: Decodable {
    let track: String
    
    enum CodingKeys: String, CodingKey {
        case track = "Track"
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


