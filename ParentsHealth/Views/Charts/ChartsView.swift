import SwiftUI
import SwiftData
import Charts

struct ChartsView: View {
    @Query(sort: \ParentProfile.name) private var parents: [ParentProfile]
    @EnvironmentObject private var parentStore: SelectedParentStore
    @EnvironmentObject private var navigationStore: AppNavigationStore

    @State private var dataSource: ChartDataSource = .vitals
    @State private var selectedMetric: MetricType = .bloodPressure
    @State private var selectedLabTest: LabTestKey = .glucose
    @State private var selectedMonth = Date()

    private var selectedParent: ParentProfile? {
        parentStore.parent(from: parents)
    }

    private var monthMetrics: [HealthMetric] {
        guard let parent = selectedParent else { return [] }
        let calendar = Calendar.current
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth))!
        let end = calendar.date(byAdding: .month, value: 1, to: start)!
        return parent.metrics
            .filter { $0.type == selectedMetric && $0.recordedAt >= start && $0.recordedAt < end }
            .sorted { $0.recordedAt < $1.recordedAt }
    }

    private var labTrendPoints: [LabTrendPoint] {
        guard let parent = selectedParent else { return [] }
        return LabTrendService.trendPoints(for: parent, testKey: selectedLabTest)
    }

    private var availableLabTests: [LabTestKey] {
        guard let parent = selectedParent else { return [] }
        return LabTrendService.availableTestKeys(for: parent)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                    if parents.isEmpty {
                        GlassCard {
                            VStack(spacing: 12) {
                                Image(systemName: "person.2.badge.plus")
                                    .font(.largeTitle)
                                    .foregroundStyle(AppTheme.softMint)
                                Text("Add a parent to view charts")
                                    .font(.sectionHeadline)
                                    .foregroundStyle(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                        }
                    } else {
                        ParentChipPicker(parents: parents, selectedParentID: $parentStore.parentID)
                        SourceSegmentPicker(source: $dataSource)

                        if dataSource == .vitals {
                            vitalsChartContent
                        } else {
                            labChartContent
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .scrollBottomClearance()
            }
            .navigationTitle("Charts")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .onAppear {
            parentStore.ensureSelection(from: parents)
            applyNavigationRequest()
            syncLabTestSelection()
            jumpToLatestMonthWithDataIfNeeded()
        }
        .onChange(of: navigationStore.chartsNavigationToken) { _, _ in
            applyNavigationRequest()
            jumpToLatestMonthWithDataIfNeeded()
        }
        .onChange(of: navigationStore.chartsDataSource) { _, _ in applyNavigationRequest() }
        .onChange(of: navigationStore.chartsMetric) { _, _ in applyNavigationRequest() }
        .onChange(of: navigationStore.chartsLabTest) { _, _ in applyNavigationRequest() }
        .onChange(of: parentStore.parentID) { _, _ in
            syncLabTestSelection()
            jumpToLatestMonthWithDataIfNeeded()
        }
        .onChange(of: selectedMetric) { _, _ in
            jumpToLatestMonthWithDataIfNeeded()
        }
        .onChange(of: dataSource) { _, newValue in
            if newValue == .vitals {
                jumpToLatestMonthWithDataIfNeeded()
            }
        }
    }

    private func applyNavigationRequest() {
        withAnimation(.spring(response: 0.3)) {
            dataSource = navigationStore.chartsDataSource
            selectedMetric = navigationStore.chartsMetric
            if availableLabTests.contains(navigationStore.chartsLabTest) {
                selectedLabTest = navigationStore.chartsLabTest
            } else if let first = availableLabTests.first {
                selectedLabTest = first
            }
        }
    }

    private func syncLabTestSelection() {
        if availableLabTests.isEmpty {
            return
        }
        if !availableLabTests.contains(selectedLabTest), let first = availableLabTests.first {
            selectedLabTest = first
        }
    }

    /// Prefer a month that actually has readings for the current parent + metric.
    private func jumpToLatestMonthWithDataIfNeeded() {
        guard dataSource == .vitals, let parent = selectedParent else { return }
        let calendar = Calendar.current
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth))!
        let end = calendar.date(byAdding: .month, value: 1, to: start)!
        let hasDataInSelectedMonth = parent.metrics.contains {
            $0.type == selectedMetric && $0.recordedAt >= start && $0.recordedAt < end
        }
        guard !hasDataInSelectedMonth else { return }

        guard let latest = parent.metrics
            .filter({ $0.type == selectedMetric })
            .map(\.recordedAt)
            .max() else { return }

        withAnimation(.spring(response: 0.3)) {
            selectedMonth = latest
        }
    }

    @ViewBuilder
    private var vitalsChartContent: some View {
        metricPicker
        monthNavigator
        vitalsChartCard
        vitalsStatsRow
    }

    @ViewBuilder
    private var labChartContent: some View {
        if availableLabTests.isEmpty {
            GlassCard {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.largeTitle)
                        .foregroundStyle(AppTheme.softMint)
                    Text("No lab data yet")
                        .font(.sectionHeadline)
                        .foregroundStyle(.white)
                    Text("Import lab reports to see trends across visits — glucose, HbA1c, cholesterol, and more.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.55))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }
        } else {
            labTestPicker
            labChartCard
            labStatsRow
            labReportTimeline
        }
    }

    private var metricPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(MetricType.allCases) { type in
                    chipButton(
                        title: type.title,
                        icon: type.icon,
                        isSelected: selectedMetric == type,
                        color: AppTheme.metricColor(for: type)
                    ) {
                        selectedMetric = type
                    }
                }
            }
        }
    }

    private var labTestPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(availableLabTests) { test in
                    chipButton(
                        title: test.title,
                        icon: test.icon,
                        isSelected: selectedLabTest == test,
                        color: test.chartColor
                    ) {
                        selectedLabTest = test
                    }
                }
            }
        }
    }

    private func chipButton(title: String, icon: String, isSelected: Bool, color: Color, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                action()
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Capsule().fill(isSelected ? color.opacity(0.5) : Color.white.opacity(0.1)))
        }
        .buttonStyle(.plain)
    }

    private var monthNavigator: some View {
        let calendar = Calendar.current
        let isCurrentMonth = calendar.isDate(selectedMonth, equalTo: Date(), toGranularity: .month)

        return HStack {
            navButton(icon: "chevron.left") {
                withAnimation(.spring(response: 0.3)) {
                    selectedMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth)!
                }
            }
            Spacer()
            Text(selectedMonth.formatted(.dateTime.month(.wide).year()))
                .font(.sectionHeadline)
                .foregroundStyle(.white)
                .contentTransition(.numericText())
            Spacer()
            navButton(icon: "chevron.right") {
                guard !isCurrentMonth else { return }
                withAnimation(.spring(response: 0.3)) {
                    selectedMonth = calendar.date(byAdding: .month, value: 1, to: selectedMonth)!
                }
            }
            .opacity(isCurrentMonth ? 0.35 : 1)
            .disabled(isCurrentMonth)
        }
    }

    private func navButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .foregroundStyle(.white)
                .padding(10)
                .liquidGlass(cornerRadius: 12, interactive: true)
        }
        .buttonStyle(.plain)
    }

    private var vitalsChartCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: selectedMetric.title, subtitle: "Daily readings this month")
                vitalsChart
            }
        }
    }

    @ViewBuilder
    private var vitalsChart: some View {
        if monthMetrics.isEmpty {
            emptyChart(message: "Log vitals to see monthly trends")
        } else {
            Chart(monthMetrics, id: \.id) { metric in
                if selectedMetric == .bloodPressure {
                    LineMark(x: .value("Date", metric.recordedAt), y: .value("Systolic", metric.value))
                        .foregroundStyle(AppTheme.metricBP)
                        .interpolationMethod(.catmullRom)
                    if let diastolic = metric.secondaryValue {
                        LineMark(x: .value("Date", metric.recordedAt), y: .value("Diastolic", diastolic))
                            .foregroundStyle(AppTheme.metricBP.opacity(0.5))
                            .interpolationMethod(.catmullRom)
                    }
                } else {
                    AreaMark(x: .value("Date", metric.recordedAt), y: .value("Value", metric.value))
                        .foregroundStyle(gradient(for: AppTheme.metricColor(for: selectedMetric)))
                        .interpolationMethod(.catmullRom)
                    LineMark(x: .value("Date", metric.recordedAt), y: .value("Value", metric.value))
                        .foregroundStyle(AppTheme.metricColor(for: selectedMetric))
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                }
            }
            .chartYAxis { AxisMarks(position: .leading) }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                    AxisValueLabel(format: .dateTime.day())
                }
            }
            .frame(height: 240)
            .animation(.spring(response: 0.45), value: selectedMetric)
            .animation(.spring(response: 0.45), value: monthMetrics.count)
        }
    }

    private var labChartCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(
                    title: selectedLabTest.title,
                    subtitle: "Across \(labTrendPoints.count) lab report\(labTrendPoints.count == 1 ? "" : "s")"
                )
                labChart
            }
        }
    }

    @ViewBuilder
    private var labChart: some View {
        if labTrendPoints.isEmpty {
            emptyChart(message: "No data for this test")
        } else {
            Chart(labTrendPoints) { point in
                AreaMark(x: .value("Date", point.date), y: .value("Value", point.value))
                    .foregroundStyle(gradient(for: selectedLabTest.chartColor))
                    .interpolationMethod(.catmullRom)

                LineMark(x: .value("Date", point.date), y: .value("Value", point.value))
                    .foregroundStyle(selectedLabTest.chartColor)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))

                PointMark(x: .value("Date", point.date), y: .value("Value", point.value))
                    .foregroundStyle(point.isAbnormal ? AppTheme.warmCoral : selectedLabTest.chartColor)
                    .symbolSize(point.isAbnormal ? 80 : 50)
            }
            .chartYAxis { AxisMarks(position: .leading) }
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
            .frame(height: 260)
            .animation(.spring(response: 0.45), value: selectedLabTest)
            .animation(.spring(response: 0.45), value: labTrendPoints.count)
        }
    }

    private var labReportTimeline: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Report History", subtitle: "Values saved per visit")
                ForEach(labTrendPoints) { point in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(point.reportTitle)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.white)
                            Text(point.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.45))
                        }
                        Spacer()
                        Text("\(formatValue(point.value)) \(selectedLabTest.unit)")
                            .font(.subheadline.weight(.semibold).monospacedDigit())
                            .foregroundStyle(point.isAbnormal ? AppTheme.warmCoral : .white)
                    }
                    if point.id != labTrendPoints.last?.id {
                        Divider().overlay(Color.white.opacity(0.1))
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var vitalsStatsRow: some View {
        if selectedMetric == .bloodPressure {
            let systolic = monthMetrics.map(\.value)
            let diastolic = monthMetrics.compactMap(\.secondaryValue)
            if let sys = stats(from: systolic), let dia = stats(from: diastolic) {
                VStack(spacing: 10) {
                    Text("Systolic")
                        .font(.captionMuted)
                        .foregroundStyle(.white.opacity(0.55))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    statsRow(min: sys.min, max: sys.max, avg: sys.avg, format: "%.0f")
                    Text("Diastolic")
                        .font(.captionMuted)
                        .foregroundStyle(.white.opacity(0.55))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    statsRow(min: dia.min, max: dia.max, avg: dia.avg, format: "%.0f")
                }
            } else if let sys = stats(from: systolic) {
                statsRow(min: sys.min, max: sys.max, avg: sys.avg, format: "%.0f")
            }
        } else {
            let values = monthMetrics.map(\.value)
            if let stats = stats(from: values) {
                let format = selectedMetric == .weight ? "%.1f" : "%.0f"
                statsRow(min: stats.min, max: stats.max, avg: stats.avg, format: format)
            }
        }
    }

    @ViewBuilder
    private var labStatsRow: some View {
        if let stats = LabTrendService.summaryStats(for: labTrendPoints) {
            let format = selectedLabTest == .hba1c || selectedLabTest == .creatinine ? "%.1f" : "%.0f"
            statsRow(min: stats.min, max: stats.max, avg: stats.avg, format: format)
        }
    }

    private func statsRow(min: Double, max: Double, avg: Double, format: String) -> some View {
        HStack(spacing: 12) {
            statChip("Avg", String(format: format, avg))
            statChip("Min", String(format: format, min))
            statChip("Max", String(format: format, max))
        }
    }

    private func statChip(_ label: String, _ value: String) -> some View {
        GlassCard(padding: 12, cornerRadius: 16) {
            VStack(spacing: 4) {
                Text(label).font(.captionMuted).foregroundStyle(.white.opacity(0.55))
                Text(value).font(.system(.title3, design: .rounded).weight(.bold)).foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func emptyChart(message: String) -> some View {
        ContentUnavailableView("No Data", systemImage: "chart.line.downtrend.xyaxis", description: Text(message))
            .frame(height: 220)
    }

    private func gradient(for color: Color) -> LinearGradient {
        LinearGradient(colors: [color.opacity(0.4), color.opacity(0.05)], startPoint: .top, endPoint: .bottom)
    }

    private func stats(from values: [Double]) -> (min: Double, max: Double, avg: Double)? {
        guard !values.isEmpty else { return nil }
        return (values.min()!, values.max()!, values.reduce(0, +) / Double(values.count))
    }

    private func formatValue(_ value: Double) -> String {
        if value == value.rounded() { return "\(Int(value))" }
        return String(format: "%.1f", value)
    }
}

#Preview {
    ChartsView()
        .environmentObject(SelectedParentStore())
        .environmentObject(AppNavigationStore())
        .modelContainer(SampleData.previewContainer)
}
