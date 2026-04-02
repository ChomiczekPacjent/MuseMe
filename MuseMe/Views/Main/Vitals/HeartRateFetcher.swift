//
//  HeartRateFetcher.swift
//  MuseMe
//
//  Created by Błażej Faber on 06/05/2025.
//

import Foundation
import HealthKit
import Combine

class HeartRateFetcher: ObservableObject {
    private let healthStore = HKHealthStore()
    private var timer: Timer?

    @Published var heartRate: Double = 0
    @Published var lastUpdated: Date? = nil
    

    init() {
        requestAuthorization()
        startFetching()
    }

    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let typesToRead: Set = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!
        ]

        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if success {
                self.fetchLatestHeartRate()
            } else {
                print("Health authorization failed:", error?.localizedDescription ?? "")
            }
        }
    }

    func startFetching() {
        fetchLatestHeartRate() // pierwszy raz od razu
        timer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { _ in
            self.fetchLatestHeartRate()
        }
    }

    func stopFetching() {
        timer?.invalidate()
    }

    func fetchLatestHeartRate() {
        let type = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, results, _ in
            guard let sample = results?.first as? HKQuantitySample else {
                return
            }

            let bpm = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
            DispatchQueue.main.async {
                self.heartRate = bpm
                self.lastUpdated = sample.endDate
            }
        }

        healthStore.execute(query)
    }
}
