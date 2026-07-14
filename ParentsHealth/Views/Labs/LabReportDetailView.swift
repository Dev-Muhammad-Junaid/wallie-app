import SwiftUI

struct LabReportDetailView: View {
    let report: LabReport
    let parent: ParentProfile

    private var previousReport: LabReport? {
        parent.labReports
            .filter { $0.effectiveDate < report.effectiveDate }
            .sorted { $0.effectiveDate > $1.effectiveDate }
            .first
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                if !report.summaryInsight.isEmpty {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Label("AI Insights", systemImage: "sparkles")
                                    .font(.sectionHeadline)
                                    .foregroundStyle(AppTheme.softMint)
                                Spacer()
                                Text(report.analysisProvider)
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.45))
                            }
                            Text(report.summaryInsight)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.85))
                        }
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(
                            title: "Extracted values",
                            subtitle: "Compared to previous report when available"
                        )

                        ForEach(sortedResults, id: \.id) { result in
                            resultRow(result)
                            if result.id != sortedResults.last?.id {
                                Divider().overlay(Color.white.opacity(0.1))
                            }
                        }
                    }
                }

                if !report.rawText.isEmpty {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Source text")
                                .font(.sectionHeadline)
                                .foregroundStyle(.white)
                            Text(report.rawText)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.5))
                                .lineLimit(10)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .scrollBottomClearance()
        }
        .background(HealthGradientBackground())
        .navigationTitle(report.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var sortedResults: [LabResult] {
        report.results.sorted { ($0.key?.title ?? $0.testName) < ($1.key?.title ?? $1.testName) }
    }

    @ViewBuilder
    private func resultRow(_ result: LabResult) -> some View {
        let previous = previousReport?.results.first { $0.testKey == result.testKey }
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(result.key?.title ?? result.testName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                Text("Ref: \(result.referenceRange)")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.45))
                if let previous {
                    let delta = result.value - previous.value
                    Text("vs prior: \(format(delta, unit: result.unit))")
                        .font(.caption2)
                        .foregroundStyle((result.key ?? .glucose).deltaColor(for: delta))
                }
            }
            Spacer()
            Text("\(result.displayValue) \(result.unit)")
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(result.isAbnormal ? AppTheme.warmCoral : .white)
        }
    }

    private func format(_ delta: Double, unit: String) -> String {
        let sign = delta >= 0 ? "+" : ""
        if delta == delta.rounded() {
            return "\(sign)\(Int(delta)) \(unit)"
        }
        return "\(sign)\(String(format: "%.1f", delta)) \(unit)"
    }
}

#Preview {
    NavigationStack {
        LabReportDetailView(report: SampleData.sampleLabReport, parent: SampleData.previewParent)
    }
}
