import SwiftUI
import SwiftData

struct ParentDetailView: View {
    @Bindable var parent: ParentProfile
    @State private var showEdit = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                heroHeader
                vitalsSection
                medicationsSection
                infoSection
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background(HealthGradientBackground())
        .navigationTitle(parent.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { showEdit = true }
                    .foregroundStyle(AppTheme.softMint)
            }
        }
        .sheet(isPresented: $showEdit) {
            ParentFormView(parent: parent)
        }
    }

    private var heroHeader: some View {
        HStack(spacing: 20) {
            ParentAvatar(initials: parent.initials, hue: parent.avatarHue, size: 80)
            VStack(alignment: .leading, spacing: 8) {
                Text("\(parent.age) years old")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                HealthScoreRing(score: parent.healthScore(), size: 90)
            }
            Spacer()
        }
        .padding(.top, 8)
    }

    private var vitalsSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent Vitals")
                    .font(.sectionHeadline)
                    .foregroundStyle(.white)

                let sorted = parent.metrics.sorted { $0.recordedAt > $1.recordedAt }.prefix(8)
                if sorted.isEmpty {
                    Text("No vitals recorded")
                        .foregroundStyle(.white.opacity(0.5))
                } else {
                    ForEach(Array(sorted), id: \.id) { metric in
                        HStack {
                            Image(systemName: metric.type.icon)
                                .foregroundStyle(AppTheme.metricColor(for: metric.type))
                                .frame(width: 24)
                            VStack(alignment: .leading) {
                                Text(metric.type.title)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.white)
                                Text(metric.recordedAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.45))
                            }
                            Spacer()
                            Text("\(metric.displayValue) \(metric.type.unit)")
                                .font(.subheadline.weight(.semibold).monospacedDigit())
                                .foregroundStyle(metric.isInNormalRange ? .white : AppTheme.warmCoral)
                        }
                        if metric.id != sorted.last?.id {
                            Divider().overlay(Color.white.opacity(0.1))
                        }
                    }
                }
            }
        }
    }

    private var medicationsSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Medications")
                    .font(.sectionHeadline)
                    .foregroundStyle(.white)

                if parent.medications.isEmpty {
                    Text("No medications added")
                        .foregroundStyle(.white.opacity(0.5))
                } else {
                    ForEach(parent.medications, id: \.id) { med in
                        MedicationRow(medication: med)
                    }
                }
            }
        }
    }

    private var infoSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Details")
                    .font(.sectionHeadline)
                    .foregroundStyle(.white)

                detailRow("Blood Type", parent.bloodType)
                if !parent.emergencyContact.isEmpty {
                    detailRow("Emergency", "\(parent.emergencyContact) · \(parent.emergencyPhone)")
                }
                if !parent.notes.isEmpty {
                    detailRow("Notes", parent.notes)
                }
            }
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.captionMuted)
                .foregroundStyle(.white.opacity(0.5))
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    NavigationStack {
        ParentDetailView(parent: SampleData.previewParent)
    }
    .modelContainer(SampleData.previewContainer)
}
