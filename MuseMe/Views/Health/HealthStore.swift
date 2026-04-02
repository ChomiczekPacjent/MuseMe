//
//  HealthStore.swift
//  MuseMe
//
//  Created by Błażej Faber on 01/05/2025.
//

import Foundation
import HealthKit
import Combine

final class HealthStore: ObservableObject {
    @Published var heartRate: Double = 0
    @Published var lastHeartRateDate: Date? = nil
    @Published var steps: Double = 0
    @Published var calories: Double = 0
    
    @Published var moodLabel: String = "Not available"

    private let healthStore = HKHealthStore()
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()

    init() {
        $heartRate
            .map { Int($0) }
            .removeDuplicates()
            .filter { $0 > 0 }
            .sink { bpm in
                SpotifyPlayerViewModel.shared.updateTargetBPM(bpm)
            }
            .store(in: &cancellables)
    }

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        let read: Set = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]

        healthStore.requestAuthorization(toShare: [], read: read) { ok, _ in
            DispatchQueue.main.async {
                if ok { self.fetchAllData() }
                completion(ok)
            }
        }
    }

    func checkIfAuthorized(completion: @escaping (Bool) -> Void) {
        let types: Set = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]

        healthStore.getRequestStatusForAuthorization(toShare: [], read: types) { status, _ in
            DispatchQueue.main.async { completion(status == .unnecessary) }
        }
    }

    func fetchAllData() {
        fetchHeartRate()
        fetchSteps()
        fetchCalories()
    }

    private func fetchHeartRate() {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
            guard let sample = samples?.first as? HKQuantitySample else { return }
            let bpm = sample.quantity.doubleValue(for: .init(from: "count/min"))
            let date = sample.endDate
            DispatchQueue.main.async {
                self.heartRate = bpm
                self.lastHeartRateDate = date
            }
        }
        healthStore.execute(query)
    }

    private func fetchSteps() {
        guard let type = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        let start = Calendar.current.startOfDay(for: Date())
        let pred = HKQuery.predicateForSamples(withStart: start, end: Date())

        let q = HKStatisticsQuery(quantityType: type,
                                  quantitySamplePredicate: pred,
                                  options: .cumulativeSum) { _, res, _ in
            let value = res?.sumQuantity()?.doubleValue(for: .count()) ?? 0
            DispatchQueue.main.async { self.steps = value }
        }
        healthStore.execute(q)
    }

    private func fetchCalories() {
        guard let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        let start = Calendar.current.startOfDay(for: Date())
        let pred = HKQuery.predicateForSamples(withStart: start, end: Date())

        let q = HKStatisticsQuery(quantityType: type,
                                  quantitySamplePredicate: pred,
                                  options: .cumulativeSum) { _, res, _ in
            let kcal = res?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
            DispatchQueue.main.async { self.calories = kcal }
        }
        healthStore.execute(q)
    }

    private func handleHeartRateSamples(_ samples: [HKSample]?) {
        guard let heartSamples = samples as? [HKQuantitySample],
              let latest = heartSamples.last else { return }

        let bpm = latest.quantity.doubleValue(for: .init(from: "count/min"))
        let date = latest.endDate

        DispatchQueue.main.async {
            self.heartRate = bpm
            self.lastHeartRateDate = date
            print("<3 HR updated: \(bpm) at \(date)")
        }
    }

    private var heartRateQuery: HKAnchoredObjectQuery?

    func startHeartRateUpdates() {
        guard let type = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }

        let predicate = HKQuery.predicateForSamples(withStart: Date(), end: nil, options: .strictStartDate)

        heartRateQuery = HKAnchoredObjectQuery(type: type,
                                               predicate: predicate,
                                               anchor: nil,
                                               limit: HKObjectQueryNoLimit) { [weak self] _, samples, _, _, _ in
            self?.handleHeartRateSamples(samples)
        }

        heartRateQuery?.updateHandler = { [weak self] _, samples, _, _, _ in
            self?.handleHeartRateSamples(samples)
        }

        if let query = heartRateQuery {
            healthStore.execute(query)
        }
    }

    private func processHeartRateSamples(_ samples: [HKSample]?) {
        guard let heartSamples = samples as? [HKQuantitySample],
              let latest = heartSamples.last else { return }

        let bpm = latest.quantity.doubleValue(for: .init(from: "count/min"))
        let date = latest.endDate

        DispatchQueue.main.async {
            self.heartRate = bpm
            self.lastHeartRateDate = date
        }
    }

    func stopHeartRateUpdates() {
        timer?.invalidate()
        timer = nil
    }
}
