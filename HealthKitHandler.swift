import Foundation
import HealthKit
import WebKit

class HealthKitHandler {
    static let shared = HealthKitHandler()
    private let healthStore = HKHealthStore()
    private let iso8601Formatter = ISO8601DateFormatter()
    
    private init() {}
    
    func setupHealthKit() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device")
            return
        }
    }
    
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .flightsClimbed)!,
            HKSeriesType.workoutRoute(),
            HKObjectType.workoutType()
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { (success, error) in
            completion(success, error)
        }
    }
    
    func checkAuthorizationStatus(completion: @escaping (HKAuthorizationStatus, Error?) -> Void) {
        let typeToCheck = HKObjectType.workoutType()
        let status = healthStore.authorizationStatus(for: typeToCheck)
        completion(status, nil)
    }
    
    func handleHealthKitPermission(webView: WKWebView) {
        requestAuthorization { success, error in
            DispatchQueue.main.async {
                if success {
                    webView.evaluateJavaScript("window.dispatchEvent(new CustomEvent('healthkit-permission-request', { detail: 'granted' }))")
                } else {
                    webView.evaluateJavaScript("window.dispatchEvent(new CustomEvent('healthkit-permission-request', { detail: 'denied' }))")
                }
            }
        }
    }
    
    func handleHealthKitData(webView: WKWebView) {
        fetchHealthData { data in
            DispatchQueue.main.async {
                let jsonData = try? JSONSerialization.data(withJSONObject: data, options: [])
                if let jsonString = String(data: jsonData!, encoding: .utf8) {
                    webView.evaluateJavaScript("window.dispatchEvent(new CustomEvent('healthkit-data', { detail: \(jsonString) }))")
                }
            }
        }
    }
    
    private func fetchHealthData(completion: @escaping ([String: Any]) -> Void) {
        let calendar = Calendar.current
        let now = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -3, to: now) else {
            completion([:])
            return
        }
        
        let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        let energyBurnedType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
        
        let stepQuery = HKStatisticsQuery(quantityType: stepCountType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            let steps = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
            let distanceQuery = HKStatisticsQuery(quantityType: distanceType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                let distance = result?.sumQuantity()?.doubleValue(for: HKUnit.meter()) ?? 0
                let energyQuery = HKStatisticsQuery(quantityType: energyBurnedType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                    let energy = result?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()) ?? 0
                    
                    self.fetchDetailedWorkouts(startDate: startDate, endDate: now) { workouts in
                        let data: [String: Any] = [
                            "steps": steps,
                            "distance": distance,
                            "energyBurned": energy,
                            "workouts": workouts
                        ]
                        completion(data)
                    }
                }
                self.healthStore.execute(energyQuery)
            }
            self.healthStore.execute(distanceQuery)
        }
        self.healthStore.execute(stepQuery)
    }
    
    private func fetchDetailedWorkouts(startDate: Date, endDate: Date, completion: @escaping ([[String: Any]]) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: .workoutType(), predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { (_, samples, error) in
            guard let workouts = samples as? [HKWorkout], error == nil else {
                completion([])
                return
            }
            
            let dispatchGroup = DispatchGroup()
            var workoutData: [[String: Any]] = []
            
            // Limit to the most recent 10 workouts, or all if less than 10
            let limitedWorkouts = Array(workouts.prefix(5))
            
            for workout in limitedWorkouts {
                dispatchGroup.enter()
                self.fetchWorkoutDetails(workout: workout) { details in
                    workoutData.append(details)
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                completion(workoutData)
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchWorkoutDetails(workout: HKWorkout, completion: @escaping ([String: Any]) -> Void) {
        var details: [String: Any] = [
            "name": workout.workoutActivityType.name,
            "start": iso8601Formatter.string(from: workout.startDate),
            "end": iso8601Formatter.string(from: workout.endDate),
            "isIndoor": workout.metadata?[HKMetadataKeyIndoorWorkout] as? Bool ?? false,
            "distance": [
                "qty": workout.totalDistance?.doubleValue(for: .meter()) ?? 0,
                "units": "m"
            ],
            "totalEnergyBurned": [
                "qty": workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0,
                "units": "kcal"
            ],
            "duration": workout.duration
        ]
        
        let dispatchGroup = DispatchGroup()
        
        // Fetch active energy burned
               dispatchGroup.enter()
               fetchActiveEnergy(for: workout) { activeEnergy in
                   details["activeEnergy"] = activeEnergy
                   dispatchGroup.leave()
               }
               
        // Fetch elevation data
        dispatchGroup.enter()
        fetchElevationData(for: workout) { elevationData in
            details["elevation"] = elevationData
            dispatchGroup.leave()
        }
        
        // Calculate speed data
        if let distanceInMeters = workout.totalDistance?.doubleValue(for: .meter()), workout.duration > 0 {
            let distanceInKm = distanceInMeters / 1000
            let speedKmPerHour = (distanceInKm / workout.duration) * 3600
            details["speed"] = [
                "qty": speedKmPerHour,
                "units": "km/hr"
            ]
        }
        
        // Fetch heart rate data
        dispatchGroup.enter()
        fetchHeartRateData(for: workout) { heartRateData, error in
            if let heartRateData = heartRateData {
                details["avgHeartRate"] = heartRateData["average"]
                details["maxHeartRate"] = heartRateData["max"]
                details["hrv"] = heartRateData["hrv"]
                details["heartRateTimeSeries"] = heartRateData["timeSeries"]
            }
            dispatchGroup.leave()
        }
        
        // Fetch route data
        dispatchGroup.enter()
        fetchRouteData(for: workout) { routeData, error in
            if let routeData = routeData {
                details["route"] = routeData
            }
            dispatchGroup.leave()
        }
        
        // Fetch step count
        dispatchGroup.enter()
        fetchStepCount(for: workout) { stepCount in
            details["stepCount"] = stepCount
            dispatchGroup.leave()
        }
        
        // Fetch flights climbed
        dispatchGroup.enter()
        fetchFlightsClimbed(for: workout) { flightsClimbed in
            details["flightsClimbed"] = flightsClimbed
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(details)
        }
    }
    
    private func fetchActiveEnergy(for workout: HKWorkout, completion: @escaping ([String: Any]) -> Void) {
           let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
           let predicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: .strictStartDate)
           
           let query = HKStatisticsQuery(quantityType: activeEnergyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
               guard let result = result, let sum = result.sumQuantity() else {
                   print("Failed to fetch active energy data: \(error?.localizedDescription ?? "Unknown error")")
                   completion(["qty": 0, "units": "kcal"])
                   return
               }
               
               let activeEnergy = sum.doubleValue(for: .kilocalorie())
               completion([
                   "qty": activeEnergy,
                   "units": "kcal"
               ])
           }
           
           healthStore.execute(query)
       }
    
    private func fetchElevationData(for workout: HKWorkout, completion: @escaping ([String: Any]) -> Void) {
        guard let flightsClimbedType = HKObjectType.quantityType(forIdentifier: .flightsClimbed) else {
            completion(["ascent": 0, "descent": 0, "units": "m"])
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: flightsClimbedType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                print("Failed to fetch flights climbed data: \(error?.localizedDescription ?? "Unknown error")")
                completion(["ascent": 0, "descent": 0, "units": "m"])
                return
            }
            
            let flightsClimbed = sum.doubleValue(for: HKUnit.count())
            
            // Estimate elevation gained: 1 flight is approximately 3 meters (10 feet)
            let estimatedElevationGained = flightsClimbed * 3.0
            
            completion([
                "ascent": estimatedElevationGained,
                "descent": 0, // We don't have descent data
                "units": "m",
                "flightsClimbed": flightsClimbed
            ])
        }
        
        healthStore.execute(query)
    }
    
    private func fetchHeartRateData(for workout: HKWorkout, completion: @escaping ([String: Any]?, Error?) -> Void) {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let predicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: .strictStartDate)
        
        let heartRateQuery = HKStatisticsQuery(quantityType: heartRateType, quantitySamplePredicate: predicate, options: [.discreteAverage, .discreteMax]) { _, result, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            let avgHeartRate = result?.averageQuantity()?.doubleValue(for: HKUnit(from: "count/min")) ?? 0
            let maxHeartRate = result?.maximumQuantity()?.doubleValue(for: HKUnit(from: "count/min")) ?? 0
            
            let hrvQuery = HKStatisticsQuery(quantityType: hrvType, quantitySamplePredicate: predicate, options: .discreteAverage) { _, hrvResult, hrvError in
                let hrv = hrvResult?.averageQuantity()?.doubleValue(for: HKUnit.secondUnit(with: .milli)) ?? 0
                
                // Fetch heart rate time series
                self.fetchHeartRateTimeSeries(for: workout) { timeSeries in
                    let heartRateData: [String: Any] = [
                        "average": ["qty": avgHeartRate, "units": "bpm"],
                        "max": ["qty": maxHeartRate, "units": "bpm"],
                        "hrv": ["qty": hrv, "units": "ms"],
                        "timeSeries": timeSeries
                    ]
                    completion(heartRateData, hrvError)
                }
            }
            
            self.healthStore.execute(hrvQuery)
        }
        
        healthStore.execute(heartRateQuery)
    }
    
    private func fetchHeartRateTimeSeries(for workout: HKWorkout, completion: @escaping ([[String: Any]]) -> Void) {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let predicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
            guard let heartRateSamples = samples as? [HKQuantitySample], error == nil else {
                completion([])
                return
            }
            
            // Define the desired number of data points
            let desiredDataPoints = 50
            
            // Calculate the sampling interval
            let samplingInterval = max(1, heartRateSamples.count / desiredDataPoints)
            
            let timeSeries = stride(from: 0, to: heartRateSamples.count, by: samplingInterval).map { index -> [String: Any] in
                let sample = heartRateSamples[index]
                return [
                    "timestamp": self.iso8601Formatter.string(from: sample.startDate),
                    "value": sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                ]
            }
            
            completion(timeSeries)
        }
        
        healthStore.execute(query)
    }
    
    private func fetchRouteData(for workout: HKWorkout, completion: @escaping ([[String: Any]]?, Error?) -> Void) {
        let routeType = HKSeriesType.workoutRoute()
        let predicate = HKQuery.predicateForObjects(from: workout)
        
        let query = HKSampleQuery(sampleType: routeType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (_, samples, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let routeSamples = samples as? [HKWorkoutRoute], let routeSample = routeSamples.first else {
                completion([], nil)
                return
            }
            
            var allLocations: [[String: Any]] = []
            
            let routeQuery = HKWorkoutRouteQuery(route: routeSample) { (query, locationsOrNil, done, errorOrNil) in
                if let error = errorOrNil {
                    completion(nil, error)
                    return
                }
                
                guard let locations = locationsOrNil else {
                    if done {
                        completion(allLocations, nil)
                    }
                    return
                }
                
                let routeData = locations.map { location -> [String: Any] in
                    return [
                        "timestamp": self.iso8601Formatter.string(from: location.timestamp),
                        "latitude": location.coordinate.latitude,
                        "longitude": location.coordinate.longitude,
                        "altitude": location.altitude
                    ]
                }
                
                allLocations.append(contentsOf: routeData)
                
                if done {
                    completion(allLocations, nil)
                }
            }
            
            self.healthStore.execute(routeQuery)
        }
        
        healthStore.execute(query)
    }
    
    private func fetchStepCount(for workout: HKWorkout, completion: @escaping ([String: Any]) -> Void) {
            let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
            let predicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: .strictStartDate)
            
            let query = HKStatisticsQuery(quantityType: stepCountType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                let steps = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                completion([
                    "qty": steps,
                    "units": "steps"
                ])
            }
            
            healthStore.execute(query)
        }
        
        private func fetchFlightsClimbed(for workout: HKWorkout, completion: @escaping ([String: Any]) -> Void) {
            let flightsClimbedType = HKQuantityType.quantityType(forIdentifier: .flightsClimbed)!
            let predicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: .strictStartDate)
            
            let query = HKStatisticsQuery(quantityType: flightsClimbedType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                let flights = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                completion([
                    "qty": flights,
                    "units": "count"
                ])
            }
            
            healthStore.execute(query)
        }
    }

    extension HKWorkoutActivityType {
        var name: String {
            switch self {
            case .americanFootball: return "American Football"
            case .archery: return "Archery"
            case .australianFootball: return "Australian Football"
            case .badminton: return "Badminton"
            case .baseball: return "Baseball"
            case .basketball: return "Basketball"
            case .bowling: return "Bowling"
            case .boxing: return "Boxing"
            case .climbing: return "Climbing"
            case .crossTraining: return "Cross Training"
            case .curling: return "Curling"
            case .cycling: return "Cycling"
            case .dance: return "Dance"
            case .danceInspiredTraining: return "Dance Inspired Training"
            case .elliptical: return "Elliptical"
            case .equestrianSports: return "Equestrian Sports"
            case .fencing: return "Fencing"
            case .fishing: return "Fishing"
            case .functionalStrengthTraining: return "Functional Strength Training"
            case .golf: return "Golf"
            case .gymnastics: return "Gymnastics"
            case .handball: return "Handball"
            case .hiking: return "Hiking"
            case .hockey: return "Hockey"
            case .hunting: return "Hunting"
            case .lacrosse: return "Lacrosse"
            case .martialArts: return "Martial Arts"
            case .mindAndBody: return "Mind and Body"
            case .mixedMetabolicCardioTraining: return "Mixed Metabolic Cardio Training"
            case .paddleSports: return "Paddle Sports"
            case .play: return "Play"
            case .preparationAndRecovery: return "Preparation and Recovery"
            case .racquetball: return "Racquetball"
            case .rowing: return "Rowing"
            case .rugby: return "Rugby"
            case .running: return "Running"
            case .sailing: return "Sailing"
            case .skatingSports: return "Skating Sports"
            case .snowSports: return "Snow Sports"
            case .soccer: return "Soccer"
            case .softball: return "Softball"
            case .squash: return "Squash"
            case .stairClimbing: return "Stair Climbing"
            case .surfingSports: return "Surfing Sports"
            case .swimming: return "Swimming"
            case .tableTennis: return "Table Tennis"
            case .tennis: return "Tennis"
            case .trackAndField: return "Track and Field"
            case .traditionalStrengthTraining: return "Traditional Strength Training"
            case .volleyball: return "Volleyball"
            case .walking: return "Walking"
            case .waterFitness: return "Water Fitness"
            case .waterPolo: return "Water Polo"
            case .waterSports: return "Water Sports"
            case .wrestling: return "Wrestling"
            case .yoga: return "Yoga"
            
            // iOS 10 additions
            case .barre: return "Barre"
            case .coreTraining: return "Core Training"
            case .crossCountrySkiing: return "Cross Country Skiing"
            case .downhillSkiing: return "Downhill Skiing"
            case .flexibility: return "Flexibility"
            case .highIntensityIntervalTraining: return "High Intensity Interval Training"
            case .jumpRope: return "Jump Rope"
            case .kickboxing: return "Kickboxing"
            case .pilates: return "Pilates"
            case .snowboarding: return "Snowboarding"
            case .stairs: return "Stairs"
            case .stepTraining: return "Step Training"
            case .wheelchairWalkPace: return "Wheelchair Walk Pace"
            case .wheelchairRunPace: return "Wheelchair Run Pace"
            
            // iOS 11 additions
            case .taiChi: return "Tai Chi"
            case .mixedCardio: return "Mixed Cardio"
            case .handCycling: return "Hand Cycling"
            
            // iOS 13 additions
            case .discSports: return "Disc Sports"
            case .fitnessGaming: return "Fitness Gaming"
            
            // iOS 14 additions
            case .cardioDance: return "Cardio Dance"
            case .socialDance: return "Social Dance"
            case .pickleball: return "Pickleball"
            case .cooldown: return "Cooldown"
            
            // Catch any undefined types
            case .cricket: return "Cricket"
            case .swimBikeRun: return "Swim Bike Run"
            case .transition: return "Transition"
            case .underwaterDiving: return "Underwater Diving"
            case .other: return "Other"
            @unknown default: return "Other"
            }
        }
    }
