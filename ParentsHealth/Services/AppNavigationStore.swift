import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case dashboard
    case parents
    case charts
    case labs
    case medications

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: return "Home"
        case .parents: return "Parents"
        case .charts: return "Charts"
        case .labs: return "Labs"
        case .medications: return "Meds"
        }
    }

    var icon: String {
        switch self {
        case .dashboard: return "house.fill"
        case .parents: return "person.2.fill"
        case .charts: return "chart.xyaxis.line"
        case .labs: return "doc.text.magnifyingglass"
        case .medications: return "pills.fill"
        }
    }
}

/// Cross-tab navigation requests (Dashboard → Charts, Labs → Charts, notification taps).
@MainActor
final class AppNavigationStore: ObservableObject {
    @Published var requestedTab: AppTab?
    @Published var chartsDataSource: ChartDataSource = .vitals
    @Published var chartsMetric: MetricType = .bloodPressure
    @Published var chartsLabTest: LabTestKey = .glucose
    /// Bumped on every charts navigation request so ChartsView re-applies even when values are unchanged.
    @Published var chartsNavigationToken = 0
    @Published var showHealthAlerts = false
    @Published var showAddMedication = false
    @Published var showCareNetwork = false

    func openCharts(metric: MetricType? = nil) {
        chartsDataSource = .vitals
        if let metric { chartsMetric = metric }
        chartsNavigationToken &+= 1
        requestedTab = .charts
    }

    func openLabTrends(testKey: LabTestKey? = nil) {
        chartsDataSource = .labs
        if let testKey { chartsLabTest = testKey }
        chartsNavigationToken &+= 1
        requestedTab = .charts
    }

    func openHealthAlerts() {
        requestedTab = .dashboard
        showHealthAlerts = true
    }

    func openCareNetwork() {
        requestedTab = .parents
        showCareNetwork = true
    }

    func openMedications() {
        requestedTab = .medications
        showAddMedication = false
    }

    func openAddMedication() {
        requestedTab = .medications
        showAddMedication = true
    }

    func consumeTabRequest() -> AppTab? {
        defer { requestedTab = nil }
        return requestedTab
    }
}
