import Foundation
import HealthKit

final class HealthKitManager {
    private let store = HKHealthStore()

    private var readTypes: Set<HKObjectType> {
        var s = Set<HKObjectType>()
        let ids: [HKQuantityTypeIdentifier] = [
            .bodyMass, .stepCount, .dietaryEnergyConsumed, .activeEnergyBurned
        ]
        for id in ids { if let t = HKObjectType.quantityType(forIdentifier: id) { s.insert(t) } }
        s.insert(HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!)
        return s
    }

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else { throw NSError(domain: "HealthKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "このiPhoneではHealthKitを利用できません。"]) }
        try await withCheckedThrowingContinuation { cont in
            store.requestAuthorization(toShare: nil, read: readTypes) { ok, error in
                if let error { cont.resume(throwing: error); return }
                if !ok { cont.resume(throwing: NSError(domain: "HealthKit", code: 2, userInfo: [NSLocalizedDescriptionKey: "Healthデータへのアクセスが許可されませんでした。"])) }
                else { cont.resume() }
            }
        }
    }

    func readToday() async throws -> [String: Any] {
        async let weight = latestQuantity(.bodyMass, unit: .gramUnit(with: .kilo))
        async let steps = sumQuantity(.stepCount, unit: .count(), start: Calendar.current.startOfDay(for: Date()))
        async let food = sumQuantity(.dietaryEnergyConsumed, unit: .kilocalorie(), start: Calendar.current.startOfDay(for: Date()))
        async let active = sumQuantity(.activeEnergyBurned, unit: .kilocalorie(), start: Calendar.current.startOfDay(for: Date()))
        async let sleep = sleepHours()
        let (w,s,f,a,sl) = try await (weight,steps,food,active,sleep)
        var out: [String: Any] = [:]
        if let w { out["weight"] = w }
        if let s { out["steps"] = s }
        if let f { out["foodKcal"] = f }
        if let a { out["activeKcal"] = a }
        if let sl { out["sleepHours"] = sl }
        return out
    }

    private func latestQuantity(_ id: HKQuantityTypeIdentifier, unit: HKUnit) async throws -> Double? {
        guard let type = HKObjectType.quantityType(forIdentifier: id) else { return nil }
        return try await withCheckedThrowingContinuation { cont in
            let q = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]) { _, samples, error in
                if let error { cont.resume(throwing: error); return }
                let sample = samples?.first as? HKQuantitySample
                cont.resume(returning: sample?.quantity.doubleValue(for: unit))
            }
            store.execute(q)
        }
    }

    private func sumQuantity(_ id: HKQuantityTypeIdentifier, unit: HKUnit, start: Date) async throws -> Double? {
        guard let type = HKObjectType.quantityType(forIdentifier: id) else { return nil }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)
        return try await withCheckedThrowingContinuation { cont in
            let q = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, error in
                if let error { cont.resume(throwing: error); return }
                cont.resume(returning: stats?.sumQuantity()?.doubleValue(for: unit))
            }
            store.execute(q)
        }
    }

    private func sleepHours() async throws -> Double? {
        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return nil }
        let start = Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: Date())) ?? Date().addingTimeInterval(-86400)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)
        return try await withCheckedThrowingContinuation { cont in
            let q = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]) { _, samples, error in
                if let error { cont.resume(throwing: error); return }
                let total = (samples as? [HKCategorySample] ?? []).filter { $0.value != HKCategoryValueSleepAnalysis.inBed.rawValue && $0.value != HKCategoryValueSleepAnalysis.awake.rawValue }.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                cont.resume(returning: total > 0 ? total / 3600.0 : nil)
            }
            store.execute(q)
        }
    }
}
