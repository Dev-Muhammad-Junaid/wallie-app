import SwiftUI

struct LabReportDetailView: View {
    let report: LabReport

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                if !report.summaryInsight.isEmpty {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("AI Insights", systemImage: "sparkles")
                                .font(.sectionHeadline)
                                .foregroundStyle(AppTheme.softMint)
                            Text(report.summaryInsight)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.85))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Extracted Values")
                            .font(.sectionHeadline)
                            .foregroundStyle(.white)

                        ForEach(report.results.sorted(by: { $0.testName < $1.testName }), id: \.id) { result in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(result.testName)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.white)
                                    Text("Ref: \(result.referenceRange)")
                                        .font(.caption2)
                                        .foregroundStyle(.white.opacity(0.45))
                                }
                                Spacer()
                                Text("\(result.displayValue) \(result.unit)")
                                    .font(.subheadline.weight(.semibold).monospacedDigit())
                                    .foregroundStyle(result.isAbnormal ? AppTheme.warmCoral : .white)
                            }
                            if result.id != report.results.last?.id {
                                Divider().overlay(Color.white.opacity(0.1))
                            }
                        }
                    }
                }

                if !report.rawText.isEmpty {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Raw OCR Text")
                                .font(.sectionHeadline)
                                .foregroundStyle(.white)
                            Text(report.rawText)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.5))
                                .lineLimit(12)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background(HealthGradientBackground())
        .navigationTitle(report.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        LabReportDetailView(report: SampleData.sampleLabReport)
    }
}
