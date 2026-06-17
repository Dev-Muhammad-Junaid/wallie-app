import Foundation

enum HealthAlertSource: String, Codable, CaseIterable {
    case vital
    case lab

    var title: String {
        switch self {
        case .vital: return "Daily Vital"
        case .lab: return "Lab Result"
        }
    }

    var icon: String {
        switch self {
        case .vital: return "waveform.path.ecg"
        case .lab: return "doc.text.magnifyingglass"
        }
    }
}

enum AlertBoundary: String, Codable {
    case belowRange
    case aboveRange
    case combinedOutOfRange

    var label: String {
        switch self {
        case .belowRange: return "Below range"
        case .aboveRange: return "Above range"
        case .combinedOutOfRange: return "Out of range"
        }
    }
}

enum AlertSeverity: Int, Codable, Comparable, CaseIterable {
    case watch = 1
    case attention = 2
    case critical = 3

    static func < (lhs: AlertSeverity, rhs: AlertSeverity) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var title: String {
        switch self {
        case .watch: return "Watch"
        case .attention: return "Needs attention"
        case .critical: return "Priority"
        }
    }

    var icon: String {
        switch self {
        case .watch: return "eye.fill"
        case .attention: return "exclamationmark.triangle.fill"
        case .critical: return "bell.badge.fill"
        }
    }
}

enum AlertTrend: String, Codable {
    case improving
    case worsening
    case stable
    case unknown

    var label: String {
        switch self {
        case .improving: return "Improving"
        case .worsening: return "Worsening"
        case .stable: return "Stable"
        case .unknown: return "No prior data"
        }
    }

    var icon: String {
        switch self {
        case .improving: return "arrow.down.right"
        case .worsening: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .unknown: return "questionmark"
        }
    }
}

struct HealthAlert: Identifiable, Equatable {
    let id: String
    let parentID: UUID
    let parentName: String
    let source: HealthAlertSource
    let title: String
    let valueText: String
    let referenceRangeText: String
    let boundary: AlertBoundary
    let severity: AlertSeverity
    let trend: AlertTrend
    let recordedAt: Date
    let healthImpact: String
    let careHint: String
    let metricType: MetricType?
    let labTestKey: LabTestKey?
    let labReportID: UUID?

    var sourceLabel: String {
        "\(source.title) · \(boundary.label)"
    }
}
