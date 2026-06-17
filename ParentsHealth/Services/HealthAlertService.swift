import Foundation

enum HealthAlertService {
  private static let recentVitalWindowDays = 7

  static func alerts(for parent: ParentProfile, referenceDate: Date = Date()) -> [HealthAlert] {
    let vitalAlerts = vitalAlerts(for: parent, referenceDate: referenceDate)
    let labAlerts = labAlerts(for: parent)
    return (vitalAlerts + labAlerts).sorted(by: sortPriority)
  }

  static func alerts(for parents: [ParentProfile], referenceDate: Date = Date()) -> [HealthAlert] {
    parents.flatMap { alerts(for: $0, referenceDate: referenceDate) }
  }

  static func alertCount(for parent: ParentProfile, referenceDate: Date = Date()) -> Int {
    alerts(for: parent, referenceDate: referenceDate).count
  }

  static func criticalCount(for parent: ParentProfile, referenceDate: Date = Date()) -> Int {
    alerts(for: parent, referenceDate: referenceDate).filter { $0.severity == .critical }.count
  }

  static func summary(for parents: [ParentProfile], referenceDate: Date = Date()) -> String {
    let all = alerts(for: parents, referenceDate: referenceDate)
    guard !all.isEmpty else {
      return "All tracked vitals and lab values are within range."
    }

    let critical = all.filter { $0.severity == .critical }.count
    let attention = all.filter { $0.severity == .attention }.count
    var parts: [String] = ["\(all.count) out-of-range indicator\(all.count == 1 ? "" : "s")"]
    if critical > 0 { parts.append("\(critical) priority") }
    if attention > 0 { parts.append("\(attention) need attention") }
    return parts.joined(separator: " · ")
  }

  static func alertIfNeeded(for metric: HealthMetric, parent: ParentProfile) -> HealthAlert? {
    guard !metric.isInNormalRange, metric.type != .weight else { return nil }
    return vitalAlert(from: metric, parent: parent)
  }

  static func labAlerts(from analysis: LabAnalysisResult, parent: ParentProfile, reportID: UUID) -> [HealthAlert] {
    analysis.results
      .filter(\.isAbnormal)
      .map { item in
        let boundary = item.testKey.boundary(for: item.value)
        return HealthAlert(
          id: "lab-\(parent.id.uuidString)-\(item.testKey.rawValue)-\(reportID.uuidString)",
          parentID: parent.id,
          parentName: parent.name,
          source: .lab,
          title: item.testName,
          valueText: "\(formatValue(item.value)) \(item.unit)",
          referenceRangeText: item.referenceRange,
          boundary: boundary,
          severity: item.testKey.severity(for: item.value),
          trend: .unknown,
          recordedAt: analysis.labDate ?? Date(),
          healthImpact: item.testKey.healthImpact(for: boundary),
          careHint: item.testKey.careHint(for: item.testKey.severity(for: item.value)),
          metricType: nil,
          labTestKey: item.testKey,
          labReportID: reportID
        )
      }
  }

  // MARK: - Vitals

  private static func vitalAlerts(for parent: ParentProfile, referenceDate: Date) -> [HealthAlert] {
    let cutoff = Calendar.current.date(byAdding: .day, value: -recentVitalWindowDays, to: referenceDate) ?? referenceDate
    let recent = parent.metrics.filter { $0.recordedAt >= cutoff }

    var latestByType: [MetricType: HealthMetric] = [:]
    for metric in recent.sorted(by: { $0.recordedAt > $1.recordedAt }) {
      if latestByType[metric.type] == nil {
        latestByType[metric.type] = metric
      }
    }

    return latestByType.values.compactMap { metric in
      guard !metric.isInNormalRange, metric.type != .weight else { return nil }
      return vitalAlert(from: metric, parent: parent)
    }
  }

  private static func vitalAlert(from metric: HealthMetric, parent: ParentProfile) -> HealthAlert {
    let boundary = metric.type.boundary(
      value: metric.value,
      secondaryValue: metric.secondaryValue
    )
    let severity = metric.type.severity(
      value: metric.value,
      secondaryValue: metric.secondaryValue
    )

    return HealthAlert(
      id: "vital-\(parent.id.uuidString)-\(metric.type.rawValue)",
      parentID: parent.id,
      parentName: parent.name,
      source: .vital,
      title: metric.type.title,
      valueText: "\(metric.displayValue) \(metric.type.unit)",
      referenceRangeText: metric.type.referenceRangeDescription,
      boundary: boundary,
      severity: severity,
      trend: .unknown,
      recordedAt: metric.recordedAt,
      healthImpact: metric.type.healthImpact(
        boundary: boundary,
        value: metric.value,
        secondaryValue: metric.secondaryValue
      ),
      careHint: metric.type.careHint(for: severity),
      metricType: metric.type,
      labTestKey: nil,
      labReportID: nil
    )
  }

  // MARK: - Labs

  private static func labAlerts(for parent: ParentProfile) -> [HealthAlert] {
    LabTrendService.availableTestKeys(for: parent).compactMap { testKey in
      guard let latest = LabTrendService.latestValue(for: parent, testKey: testKey),
            latest.isAbnormal else { return nil }
      return labAlert(from: latest, testKey: testKey, parent: parent)
    }
  }

  private static func labAlert(
    from point: LabTrendPoint,
    testKey: LabTestKey,
    parent: ParentProfile
  ) -> HealthAlert {
    let result = parent.labReports
      .flatMap(\.results)
      .first { $0.id == point.id }

    let boundary = testKey.boundary(for: point.value)
    let severity = testKey.severity(for: point.value)
    let trend = labTrend(for: parent, testKey: testKey, current: point)
    let referenceText = result?.referenceRange ?? testKey.referenceRangeDescription

    return HealthAlert(
      id: "lab-\(parent.id.uuidString)-\(testKey.rawValue)",
      parentID: parent.id,
      parentName: parent.name,
      source: .lab,
      title: testKey.title,
      valueText: "\(formatValue(point.value)) \(testKey.unit)",
      referenceRangeText: referenceText,
      boundary: boundary,
      severity: severity,
      trend: trend,
      recordedAt: point.date,
      healthImpact: testKey.healthImpact(for: boundary),
      careHint: testKey.careHint(for: severity),
      metricType: nil,
      labTestKey: testKey,
      labReportID: point.reportID
    )
  }

  private static func labTrend(
    for parent: ParentProfile,
    testKey: LabTestKey,
    current: LabTrendPoint
  ) -> AlertTrend {
    let points = LabTrendService.trendPoints(for: parent, testKey: testKey)
    guard points.count >= 2,
          let previous = points.dropLast().last,
          previous.id != current.id || points.count > 2 else {
      if points.count < 2 { return .unknown }
      let prior = points[points.count - 2]
      return trendDirection(from: prior.value, to: current.value, highIsBad: testKey.highIsBad)
    }

    let prior = points[points.count - 2]
    return trendDirection(from: prior.value, to: current.value, highIsBad: testKey.highIsBad)
  }

  private static func trendDirection(from previous: Double, to current: Double, highIsBad: Bool) -> AlertTrend {
    let delta = current - previous
    if abs(delta) < 0.01 { return .stable }

    if highIsBad {
      if delta > 0 { return .worsening }
      return .improving
    }

    if delta < 0 { return .worsening }
    return .improving
  }

  private static func sortPriority(_ lhs: HealthAlert, _ rhs: HealthAlert) -> Bool {
    if lhs.severity != rhs.severity {
      return lhs.severity > rhs.severity
    }
    if lhs.trend != rhs.trend {
      if lhs.trend == .worsening { return true }
      if rhs.trend == .worsening { return false }
    }
    return lhs.recordedAt > rhs.recordedAt
  }

  private static func formatValue(_ value: Double) -> String {
    if value == value.rounded() { return "\(Int(value))" }
    return String(format: "%.1f", value)
  }
}
