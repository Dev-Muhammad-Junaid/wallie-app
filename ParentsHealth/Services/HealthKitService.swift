import Foundation
import HealthKit
import SwiftData

@MainActor
final class HealthKitService: ObservableObject {
    static let shared = HealthKitService()

    private let store = HKHealthStore()

    @Published private(set) var isAvailable = HKHealthStore.isHealthDataAvailable()
    @Published private(set) var isAuthorized = false
    @Published private(set) var lastSyncDate: Date?
    @Published var lastSyncMessage = ""

    private init() {}

    func requestAuthorization() async throws {
        guard isAvailable else {
            throw HealthKitError.notAvailable
        }

        let readTypes: Set<HKObjectType> = [
            HKQuantityType(.bloodPressureSystolic),
            HKQuantityType(.bloodPressureDiastolic),
            HKQuantityType(.bodyMass),
            HKQuantityType(.heartRate),
            HKQuantityType(.bloodGlucose)
        ]

        try await store.requestAuthorization(toShare: [], read: readTypes)
        isAuthorized = true
    }

    func syncMetrics(for parent: ParentProfile, context: ModelContext, days: Int = 14) async throws -> Int {
        guard isAvailable else {
            throw HealthKitError.notAvailable
        }

        let since = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        var imported = 0

        imported += try await importBloodPressure(for: parent, context: context, since: since)
        imported += try await importQuantity(
            type: .bodyMass, metricType: .weight, unit: .gramUnit(with: .kilo),
            for: parent, context: context, since: since
        )
        imported += try await importQuantity(
            type: .heartRate, metricType: .heartRate, unit: .count().unitDivided(by: .minute()),
            for: parent, context: context, since: since
        )
        imported += try await importQuantity(
            type: .bloodGlucose, metricType: .bloodGlucose, unit: .gramUnit(with: .milli).unitDivided(by: .liter()),
            for: parent, context: context, since: since, factor: 18.0182 // mmol/L to mg/dL if needed
        )

        lastSyncDate = Date()
        lastSyncMessage = "Imported \(imported) readings from HealthKit"
        return imported
    }

    private func importBloodPressure(for parent: ParentProfile, context: ModelContext, since: Date) async throws -> Int {
        let systolicType = HKQuantityType(.bloodPressureSystolic)
        let predicate = HKQuery.predicateForSamples(withStart: since, end: Date())
        let samples: [HKQuantitySample] = try await fetchSamples(type: systolicType, predicate: predicate)

        var imported = 0
        for sample in samples {
            guard !metricExists(parent: parent, date: sample.startDate, type: .bloodPressure) else { continue }

            let diastolic = try await diastolicValue(for: sample)
            let systolic = sample.quantity.doubleValue(for: .millimeterOfMercury())

            let metric = HealthMetric(
                type: .bloodPressure,
                value: systolic,
                secondaryValue: diastolic,
                notes: "Imported from HealthKit",
                recordedAt: sample.startDate,
                parent: parent
            )
            context.insert(metric)
            imported += 1
        }
        return imported
    }

    private func diastolicValue(for systolicSample: HKQuantitySample) async throws -> Double {
        guard let bpType = HKCorrelationType.correlationType(forIdentifier: .bloodPressure),
              let correlation = try await fetchCorrelations(type: bpType, around: systolicSample.startDate).first,
              let diastolic = correlation.objects(for: HKQuantityType(.bloodPressureDiastolic)).first as? HKQuantitySample
        else { return 80 }

        return diastolic.quantity.doubleValue(for: .millimeterOfMercury())
    }

    private func importQuantity(
        type: HKQuantityTypeIdentifier,
        metricType: MetricType,
        unit: HKUnit,
        for parent: ParentProfile,
        context: ModelContext,
        since: Date,
        factor: Double = 1.0
    ) async throws -> Int {
        let quantityType = HKQuantityType(type)
        let predicate = HKQuery.predicateForSamples(withStart: since, end: Date())
        let samples: [HKQuantitySample] = try await fetchSamples(type: quantityType, predicate: predicate)

        var imported = 0
        for sample in samples {
            guard !metricExists(parent: parent, date: sample.startDate, type: metricType) else { continue }

            let value = sample.quantity.doubleValue(for: unit) * factor
            let metric = HealthMetric(
                type: metricType,
                value: value,
                notes: "Imported from HealthKit",
                recordedAt: sample.startDate,
                parent: parent
            )
            context.insert(metric)
            imported += 1
        }
        return imported
    }

    private func metricExists(parent: ParentProfile, date: Date, type: MetricType) -> Bool {
        parent.metrics.contains {
            $0.type == type && abs($0.recordedAt.timeIntervalSince(date)) < 60
        }
    }

    private func fetchSamples(type: HKQuantityType, predicate: NSPredicate) async throws -> [HKQuantitySample] {
        try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: samples as? [HKQuantitySample] ?? [])
            }
            store.execute(query)
        }
    }

    private func fetchCorrelations(type: HKCorrelationType, around date: Date) async throws -> [HKCorrelation] {
        let start = date.addingTimeInterval(-5)
        let end = date.addingTimeInterval(5)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: 10,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: samples as? [HKCorrelation] ?? [])
            }
            store.execute(query)
        }
    }

    enum HealthKitError: LocalizedError {
        case notAvailable

        var errorDescription: String? {
            switch self {
            case .notAvailable: return "HealthKit is not available on this device."
            }
        }
    }
}
