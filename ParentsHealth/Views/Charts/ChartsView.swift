import SwiftUI
import SwiftData
import Charts

struct ChartsView: View {
    @Query(sort: \ParentProfile.name) private var parents: [ParentProfile]
    @State private var selectedParentID: UUID?
    @State private var selectedMetric: MetricType = .bloodPressure
    @State private var selectedMonth = Date()

    private var selectedParent: ParentProfile? {
        if let id = selectedParentID {
            return parents.first { $0.id == id }
        }
        return parents.first
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

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                    parentPicker
                    metricPicker
                    monthNavigator
                    chartCard
                    statsRow
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 120)
            }
            .navigationTitle("Charts")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .onAppear {
            selectedParentID = parents.first?.id
        }
    }

    private var parentPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(parents) { parent in
                    Button {
                        selectedParentID = parent.id
                    } label: {
                        Text(parent.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .liquidGlass(cornerRadius: 16, interactive: true)
                            .opacity(selectedParent?.id == parent.id ? 1 : 0.55)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var metricPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(MetricType.allCases) { type in
                    Button {
                        withAnimation { selectedMetric = type }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: type.icon)
                            Text(type.title)
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(selectedMetric == type
                                      ? AppTheme.metricColor(for: type).opacity(0.5)
                                      : Color.white.opacity(0.1))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var monthNavigator: some View {
        HStack {
            Button {
                selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth)!
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(.white)
                    .padding(10)
                    .liquidGlass(cornerRadius: 12, interactive: true)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(selectedMonth.formatted(.dateTime.month(.wide).year()))
                .font(.sectionHeadline)
                .foregroundStyle(.white)

            Spacer()

            Button {
                selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth)!
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundStyle(.white)
                    .padding(10)
                    .liquidGlass(cornerRadius: 12, interactive: true)
            }
            .buttonStyle(.plain)
        }
    }

    private var chartCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text(selectedMetric.title)
                    .font(.sectionHeadline)
                    .foregroundStyle(.white)

                if monthMetrics.isEmpty {
                    ContentUnavailableView(
                        "No Data",
                        systemImage: "chart.line.downtrend.xyaxis",
                        description: Text("Log vitals to see monthly trends")
                    )
                    .frame(height: 220)
                } else {
                    Chart(monthMetrics, id: \.id) { metric in
                        if selectedMetric == .bloodPressure {
                            LineMark(
                                x: .value("Date", metric.recordedAt),
                                y: .value("Systolic", metric.value)
                            )
                            .foregroundStyle(AppTheme.metricBP)
                            .interpolationMethod(.catmullRom)

                            if let diastolic = metric.secondaryValue {
                                LineMark(
                                    x: .value("Date", metric.recordedAt),
                                    y: .value("Diastolic", diastolic)
                                )
                                .foregroundStyle(AppTheme.metricBP.opacity(0.5))
                                .interpolationMethod(.catmullRom)
                            }
                        } else {
                            AreaMark(
                                x: .value("Date", metric.recordedAt),
                                y: .value("Value", metric.value)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        AppTheme.metricColor(for: selectedMetric).opacity(0.4),
                                        AppTheme.metricColor(for: selectedMetric).opacity(0.05)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)

                            LineMark(
                                x: .value("Date", metric.recordedAt),
                                y: .value("Value", metric.value)
                            )
                            .foregroundStyle(AppTheme.metricColor(for: selectedMetric))
                            .interpolationMethod(.catmullRom)
                            .lineStyle(StrokeStyle(lineWidth: 2.5))
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { _ in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(Color.white.opacity(0.15))
                            AxisValueLabel()
                                .foregroundStyle(Color.white.opacity(0.6))
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                            AxisValueLabel(format: .dateTime.day())
                                .foregroundStyle(Color.white.opacity(0.6))
                        }
                    }
                    .frame(height: 240)
                }
            }
        }
    }

    private var statsRow: some View {
        let values = monthMetrics.map(\.value)
        guard !values.isEmpty else { return AnyView(EmptyView()) }

        let avg = values.reduce(0, +) / Double(values.count)
        let min = values.min() ?? 0
        let max = values.max() ?? 0

        return AnyView(
            HStack(spacing: 12) {
                statChip("Avg", String(format: selectedMetric == .weight ? "%.1f" : "%.0f", avg))
                statChip("Min", String(format: selectedMetric == .weight ? "%.1f" : "%.0f", min))
                statChip("Max", String(format: selectedMetric == .weight ? "%.1f" : "%.0f", max))
            }
        )
    }

    private func statChip(_ label: String, _ value: String) -> some View {
        GlassCard(padding: 12, cornerRadius: 16) {
            VStack(spacing: 4) {
                Text(label)
                    .font(.captionMuted)
                    .foregroundStyle(.white.opacity(0.55))
                Text(value)
                    .font(.title3.weight(.bold).rounded())
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    ChartsView()
        .modelContainer(SampleData.previewContainer)
}
