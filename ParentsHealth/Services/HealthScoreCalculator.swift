import Foundation

enum HealthScoreCalculator {
    /// Composite health score (60–100) from recent metric normal-range ratio.
    static func score(from metrics: [HealthMetricSnapshot], withinDays days: Int = 7, referenceDate: Date = Date()) -> Int {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: referenceDate)!
        let recent = metrics.filter { $0.recordedAt > cutoff }
        guard !recent.isEmpty else { return 75 }

        let normalCount = recent.filter(\.isInNormalRange).count
        let ratio = Double(normalCount) / Double(recent.count)
        return Int(60 + ratio * 40)
    }
}

/// Lightweight value type for testable health score logic.
struct HealthMetricSnapshot {
    let type: MetricType
    let value: Double
    let secondaryValue: Double?
    let recordedAt: Date

    var isInNormalRange: Bool {
        type.isNormal(value: value, secondaryValue: secondaryValue)
    }

    init(type: MetricType, value: Double, secondaryValue: Double? = nil, recordedAt: Date = Date()) {
        self.type = type
        self.value = value
        self.secondaryValue = secondaryValue
        self.recordedAt = recordedAt
    }

    init(metric: HealthMetric) {
        self.type = metric.type
        self.value = metric.value
        self.secondaryValue = metric.secondaryValue
        self.recordedAt = metric.recordedAt
    }
}
