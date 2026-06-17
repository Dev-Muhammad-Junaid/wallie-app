import SwiftUI
import SwiftData

struct LabReportsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var parentStore: SelectedParentStore
    @Query(sort: \ParentProfile.name) private var parents: [ParentProfile]
    @State private var showImport = false

    private var selectedParent: ParentProfile? {
        parentStore.parent(from: parents)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                    ParentChipPicker(parents: parents, selectedParentID: $parentStore.parentID)

                    if let parent = selectedParent {
                        howItWorksCard
                        trendOverview(for: parent)

                        if parent.labReports.isEmpty {
                            emptyState
                        } else {
                            SectionHeader(
                                title: "Saved reports",
                                subtitle: "\(parent.labReports.count) report\(parent.labReports.count == 1 ? "" : "s") · tied to charts"
                            )

                            ForEach(sortedReports(for: parent), id: \.id) { report in
                                NavigationLink {
                                    LabReportDetailView(report: report, parent: parent)
                                } label: {
                                    LabReportCard(report: report)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button("Delete", role: .destructive) {
                                        modelContext.delete(report)
                                    }
                                }
                            }
                        }
                    } else {
                        GlassCard {
                            Text("Add a parent profile to manage lab reports.")
                                .foregroundStyle(.white.opacity(0.6))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 24)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 120)
            }
            .navigationTitle("Lab Reports")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showImport = true } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .disabled(selectedParent == nil)
                }
            }
        }
        .sheet(isPresented: $showImport) {
            if let parent = selectedParent {
                ImportLabReportView(parent: parent)
            }
        }
        .onAppear {
            parentStore.ensureSelection(from: parents)
        }
    }

    private var howItWorksCard: some View {
        GlassCard(padding: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Label("How lab reports work", systemImage: "info.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.softMint)
                Text("1. Import photo or paste text → 2. On-device AI extracts values → 3. Saved per parent → 4. Charts show trends over time.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }

    @ViewBuilder
    private func trendOverview(for parent: ParentProfile) -> some View {
        let keys = LabTrendService.availableTestKeys(for: parent)
        if !keys.isEmpty {
            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Tracked markers", subtitle: "View full trends in Charts → Lab Trends")
                    ForEach(keys.prefix(4)) { key in
                        if let latest = LabTrendService.latestValue(for: parent, testKey: key) {
                            let points = LabTrendService.trendPoints(for: parent, testKey: key)
                            let previous = points.count > 1 ? points[points.count - 2] : nil
                            HStack {
                                Image(systemName: key.icon)
                                    .foregroundStyle(key.chartColor)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(key.title)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.white)
                                    Text(latest.date.formatted(date: .abbreviated, time: .omitted))
                                        .font(.caption2)
                                        .foregroundStyle(.white.opacity(0.45))
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("\(format(latest.value)) \(key.unit)")
                                        .font(.subheadline.weight(.bold).monospacedDigit())
                                        .foregroundStyle(latest.isAbnormal ? AppTheme.warmCoral : .white)
                                    if let delta = LabTrendService.delta(from: previous, to: latest) {
                                        Text(delta >= 0 ? "+\(format(delta))" : format(delta))
                                            .font(.caption2)
                                            .foregroundStyle(delta > 0 ? AppTheme.warmCoral.opacity(0.9) : AppTheme.softMint)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        GlassCard {
            VStack(spacing: 14) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.largeTitle)
                    .foregroundStyle(AppTheme.softMint)
                Text("No lab reports yet")
                    .font(.sectionHeadline)
                    .foregroundStyle(.white)
                Text("Tap + to snap a photo or paste text. Values are saved and charted automatically.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                Button("Add first report") { showImport = true }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.deepTeal)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
        }
    }

    private func sortedReports(for parent: ParentProfile) -> [LabReport] {
        parent.labReports.sorted { $0.effectiveDate > $1.effectiveDate }
    }

    private func format(_ value: Double) -> String {
        if value == value.rounded() { return "\(Int(value))" }
        return String(format: "%.1f", value)
    }
}

struct LabReportCard: View {
    let report: LabReport

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(report.title)
                        .font(.sectionHeadline)
                        .foregroundStyle(.white)
                    Spacer()
                    if report.abnormalCount > 0 {
                        Text("\(report.abnormalCount) flagged")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.warmCoral)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(AppTheme.warmCoral.opacity(0.2)))
                    }
                }

                HStack(spacing: 12) {
                    Label(report.effectiveDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                    Label(report.analysisProvider, systemImage: "cpu")
                }
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))

                Text("\(report.results.count) values · charts update automatically")
                    .font(.caption)
                    .foregroundStyle(AppTheme.softMint.opacity(0.9))
            }
        }
    }
}

#Preview {
    LabReportsView()
        .environmentObject(SelectedParentStore())
        .modelContainer(SampleData.previewContainer)
}
