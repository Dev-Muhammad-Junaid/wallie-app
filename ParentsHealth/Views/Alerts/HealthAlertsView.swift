import SwiftUI
import SwiftData

struct HealthAlertsView: View {
    @Query(sort: \ParentProfile.name) private var parents: [ParentProfile]
    @EnvironmentObject private var parentStore: SelectedParentStore
    @Environment(\.dismiss) private var dismiss
    @State private var filterSource: HealthAlertSource?

    private var alerts: [HealthAlert] {
        let scoped = parentStore.parent(from: parents).map {
            HealthAlertService.alerts(for: $0)
        } ?? HealthAlertService.alerts(for: parents)
        guard let filterSource else { return scoped }
        return scoped.filter { $0.source == filterSource }
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                    SectionHeader(
                        title: "Health Alerts",
                        subtitle: "Out-of-range vitals and lab markers with what they may mean for the body."
                    )

                    ParentChipPicker(parents: parents, selectedParentID: $parentStore.parentID)

                    filterChips

                    if alerts.isEmpty {
                        allClearCard
                    } else {
                        summaryCard
                        ForEach(alerts) { alert in
                            HealthAlertCard(alert: alert)
                        }
                    }

                    disclaimerCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 20)
            }
            .background(HealthGradientBackground())
            .navigationTitle("Health Alerts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .accessibilityIdentifier("healthAlertsView")
        }
        .onAppear {
            parentStore.ensureSelection(from: parents)
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(title: "All", source: nil)
                ForEach(HealthAlertSource.allCases, id: \.self) { source in
                    filterChip(title: source.title, source: source)
                }
            }
        }
    }

    private func filterChip(title: String, source: HealthAlertSource?) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                filterSource = source
            }
        } label: {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(filterSource == source ? AppTheme.deepTeal.opacity(0.7) : Color.white.opacity(0.1))
                )
        }
        .buttonStyle(.plain)
    }

    private var allClearCard: some View {
        GlassCard {
            VStack(spacing: 14) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(AppTheme.softMint)
                Text("All in range")
                    .font(.sectionHeadline)
                    .foregroundStyle(.white)
                Text("No out-of-range vitals in the last 7 days and no flagged lab results for the selected parent.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
    }

    private var summaryCard: some View {
        GlassCard(padding: 14) {
            HStack(spacing: 12) {
                Image(systemName: "bell.badge.fill")
                    .font(.title2)
                    .foregroundStyle(AppTheme.warmCoral)
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(alerts.count) active alert\(alerts.count == 1 ? "" : "s")")
                        .font(.sectionHeadline)
                        .foregroundStyle(.white)
                    Text(HealthAlertService.summary(for: parentStore.parent(from: parents).map { [$0] } ?? parents))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
            }
        }
    }

    private var disclaimerCard: some View {
        GlassCard(padding: 14) {
            Label("Educational only — not medical advice", systemImage: "info.circle")
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.55))
        }
    }
}

struct HealthAlertCard: View {
    let alert: HealthAlert

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    Image(systemName: alert.source.icon)
                        .font(.title3)
                        .foregroundStyle(severityColor)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(alert.title)
                            .font(.sectionHeadline)
                            .foregroundStyle(.white)
                        Text(alert.parentName)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.55))
                    }

                    Spacer()

                    SeverityBadge(severity: alert.severity)
                }

                HStack(alignment: .firstTextBaseline) {
                    Text(alert.valueText)
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundStyle(severityColor)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Target: \(alert.referenceRangeText)")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.55))
                        Text(alert.boundary.label)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(severityColor)
                    }
                }

                if alert.trend != .unknown {
                    HStack(spacing: 6) {
                        Image(systemName: alert.trend.icon)
                        Text(alert.trend.label)
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(alert.trend == .worsening ? AppTheme.warmCoral : AppTheme.softMint)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Label("What this can affect", systemImage: "heart.text.square")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.7))
                    Text(alert.healthImpact)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))

                HStack(spacing: 8) {
                    Image(systemName: "hand.point.right.fill")
                        .font(.caption)
                    Text(alert.careHint)
                        .font(.caption)
                }
                .foregroundStyle(.white.opacity(0.6))

                Text(alert.recordedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(alert.title), \(alert.severity.title), \(alert.valueText)")
    }

    private var severityColor: Color {
        switch alert.severity {
        case .critical: return AppTheme.warmCoral
        case .attention: return Color.orange
        case .watch: return Color.yellow.opacity(0.9)
        }
    }
}

struct SeverityBadge: View {
    let severity: AlertSeverity

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: severity.icon)
            Text(severity.title)
        }
        .font(.caption2.weight(.bold))
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Capsule().fill(backgroundColor))
    }

    private var backgroundColor: Color {
        switch severity {
        case .critical: return AppTheme.warmCoral.opacity(0.85)
        case .attention: return Color.orange.opacity(0.85)
        case .watch: return Color.yellow.opacity(0.75)
        }
    }
}

struct DashboardAlertsSummary: View {
    let parent: ParentProfile
    var onSeeAll: () -> Void

    private var alerts: [HealthAlert] {
        HealthAlertService.alerts(for: parent)
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("Health Alerts", systemImage: "bell.badge.fill")
                        .font(.sectionHeadline)
                        .foregroundStyle(.white)
                    Spacer()
                    if !alerts.isEmpty {
                        Text("\(alerts.count)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(AppTheme.warmCoral))
                    }
                }

                if alerts.isEmpty {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AppTheme.softMint)
                        Text("Vitals and labs are within range")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.65))
                    }
                } else {
                    ForEach(alerts.prefix(3)) { alert in
                        HStack(spacing: 10) {
                            SeverityBadge(severity: alert.severity)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(alert.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                                Text("\(alert.valueText) · \(alert.boundary.label)")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.55))
                            }
                            Spacer()
                        }
                    }

                    if alerts.count > 3 {
                        Text("+\(alerts.count - 3) more")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.45))
                    }
                }

                Button(action: onSeeAll) {
                    Text(alerts.isEmpty ? "View alert center" : "See all alerts & analysis")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.softMint)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("seeAllAlertsButton")
            }
        }
    }
}

#Preview {
    HealthAlertsView()
        .environmentObject(SelectedParentStore())
        .modelContainer(SampleData.previewContainer)
}
