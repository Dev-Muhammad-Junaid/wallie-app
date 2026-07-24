import SwiftUI
import SwiftData

struct DashboardView: View {
    var onOpenSettings: () -> Void = {}
    var onOpenCharts: (MetricType?) -> Void = { _ in }
    var onOpenAlerts: () -> Void = {}
    var onOpenCare: () -> Void = {}

    @EnvironmentObject private var parentStore: SelectedParentStore
    @Query(sort: \ParentProfile.name) private var parents: [ParentProfile]

    private var selectedParent: ParentProfile? {
        parentStore.parent(from: parents)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                    headerSection
                    parentChips
                    bentoGrid
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .scrollBottomClearance()
            }
            .navigationBarHidden(true)
            .overlay(alignment: .topTrailing) {
                HStack(spacing: 10) {
                    alertsHeaderButton
                    Button(action: onOpenSettings) {
                        Image(systemName: "gearshape.fill")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.8))
                            .padding(12)
                            .liquidGlass(cornerRadius: 14, interactive: true)
                    }
                    .accessibilityIdentifier("settingsButton")
                }
                .padding(.trailing, 20)
                .padding(.top, 8)
            }
        }
        .onAppear {
            parentStore.ensureSelection(from: parents)
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(greeting)
                .font(.captionMuted)
                .foregroundStyle(.white.opacity(0.65))
            Text("ParentsHealth")
                .font(.displayTitle)
                .foregroundStyle(.white)
            Text("Keeping loved ones in check, privately.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private var parentChips: some View {
        ParentChipPicker(parents: parents, selectedParentID: $parentStore.parentID)
    }

    @ViewBuilder
    private var bentoGrid: some View {
        Group {
            if let parent = selectedParent {
                parentDashboardContent(parent)
            } else {
                GlassCard {
                    VStack(spacing: 12) {
                        Image(systemName: "person.2.badge.plus")
                            .font(.largeTitle)
                            .foregroundStyle(AppTheme.softMint)
                        Text("Add a parent profile to get started")
                            .font(.sectionHeadline)
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: parentStore.parentID)
    }

    @ViewBuilder
    private func parentDashboardContent(_ parent: ParentProfile) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
            HStack(alignment: .top, spacing: 14) {
                GlassCard(padding: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Health Score")
                            .font(.sectionHeadline)
                            .foregroundStyle(.white)
                        HealthScoreRing(score: parent.healthScore())
                    }
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 14) {
                    GlassCard(padding: 14) {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Age", systemImage: "calendar")
                                .font(.captionMuted)
                                .foregroundStyle(.white.opacity(0.6))
                            Text("\(parent.age) yrs")
                                .font(.system(.title2, design: .rounded).weight(.bold))
                                .foregroundStyle(.white)
                        }
                    }
                    GlassCard(padding: 14) {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Blood", systemImage: "drop.fill")
                                .font(.captionMuted)
                                .foregroundStyle(.white.opacity(0.6))
                            Text(parent.bloodType)
                                .font(.system(.title2, design: .rounded).weight(.bold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .frame(width: 130)
            }
            .transition(.opacity.combined(with: .move(edge: .leading)))

            DashboardAlertsSummary(parent: parent) {
                onOpenAlerts()
            }

            if let next = parent.nextAppointment {
                Button {
                    onOpenCare()
                } label: {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Next Appointment")
                                    .font(.sectionHeadline)
                                    .foregroundStyle(.white)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.35))
                            }
                            Text(next.displayTitle)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                            Text("\(next.scheduledAt.formatted(date: .abbreviated, time: .shortened)) · \(next.providerName)")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.55))
                        }
                    }
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    onOpenCare()
                } label: {
                    GlassCard {
                        HStack(spacing: 12) {
                            Image(systemName: "stethoscope")
                                .foregroundStyle(AppTheme.softMint)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Care Network")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                                Text("Doctors, contacts, and visits")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.35))
                        }
                    }
                }
                .buttonStyle(.plain)
            }

            GlassCard {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("Recent Vitals")
                            .font(.sectionHeadline)
                            .foregroundStyle(.white)
                        Spacer()
                        Button {
                            onOpenCharts(nil)
                        } label: {
                            HStack(spacing: 4) {
                                Text("Charts")
                                    .font(.captionMuted)
                                Image(systemName: "chevron.right")
                                    .font(.caption2.weight(.semibold))
                            }
                            .foregroundStyle(AppTheme.softMint)
                        }
                        .buttonStyle(.plain)
                    }

                    let recent = parent.recentMetrics(withinDays: 7)
                    if recent.isEmpty {
                        Text("No vitals in the last 7 days. Use the log button below.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.5))
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(recent, id: \.id) { metric in
                                Button {
                                    onOpenCharts(metric.type)
                                } label: {
                                    MetricChip(
                                        title: metric.type.title,
                                        value: metric.displayValue,
                                        unit: metric.type.unit,
                                        color: AppTheme.metricColor(for: metric.type)
                                    )
                                }
                                .buttonStyle(.plain)
                                .accessibilityHint("View \(metric.type.title) chart")
                            }
                        }
                    }
                }
            }

            if !parent.medications.filter(\.isActive).isEmpty {
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Today's Medications")
                            .font(.sectionHeadline)
                            .foregroundStyle(.white)

                        ForEach(parent.medications.filter(\.isActive), id: \.id) { med in
                            MedicationRow(medication: med, compact: true)
                        }
                    }
                }
            }

            if !parent.conditions.isEmpty {
                GlassCard(padding: 14) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Conditions")
                            .font(.sectionHeadline)
                            .foregroundStyle(.white)
                        FlowLayout(spacing: 8) {
                            ForEach(parent.conditions, id: \.self) { condition in
                                Text(condition)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Capsule().fill(Color.white.opacity(0.12)))
                            }
                        }
                    }
                }
            }
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    @ViewBuilder
    private var alertsHeaderButton: some View {
        let count = selectedParent.map { HealthAlertService.alertCount(for: $0) } ?? 0
        Button {
            onOpenAlerts()
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(12)
                    .liquidGlass(cornerRadius: 14, interactive: true)

                if count > 0 {
                    Text("\(min(count, 9))")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 18, height: 18)
                        .background(Circle().fill(AppTheme.warmCoral))
                        .offset(x: 4, y: -4)
                }
            }
        }
        .accessibilityIdentifier("alertsHeaderButton")
        .accessibilityLabel(count > 0 ? "\(count) health alerts" : "Health alerts")
    }
}

/// Simple flow layout for condition tags.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x)
        }

        return (CGSize(width: maxX, height: y + rowHeight), positions)
    }
}

#Preview {
    DashboardView()
        .environmentObject(SelectedParentStore())
        .modelContainer(SampleData.previewContainer)
}
