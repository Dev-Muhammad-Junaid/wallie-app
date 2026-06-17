import SwiftUI
import SwiftData

struct MedicationsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ParentProfile.name) private var parents: [ParentProfile]
    @State private var showAddMedication = false

    private var allMedications: [(ParentProfile, Medication)] {
        parents.flatMap { parent in
            parent.medications.map { (parent, $0) }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                if allMedications.isEmpty {
                    GlassCard {
                        VStack(spacing: 14) {
                            Image(systemName: "pills.fill")
                                .font(.largeTitle)
                                .foregroundStyle(AppTheme.warmCoral)
                            Text("No medications yet")
                                .font(.sectionHeadline)
                                .foregroundStyle(.white)
                            Text("Add medications to track reminders and adherence")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.5))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                } else {
                    LazyVStack(spacing: 14) {
                        ForEach(allMedications, id: \.1.id) { parent, medication in
                            GlassCard {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Text(medication.name)
                                            .font(.sectionHeadline)
                                            .foregroundStyle(.white)
                                        Spacer()
                                        Text(parent.name)
                                            .font(.caption)
                                            .foregroundStyle(.white.opacity(0.5))
                                    }

                                    MedicationRow(medication: medication)

                                    HStack {
                                        Text("Adherence")
                                            .font(.caption)
                                            .foregroundStyle(.white.opacity(0.5))
                                        Spacer()
                                        Text("\(Int(medication.adherenceThisWeek * 100))%")
                                            .font(.subheadline.weight(.bold).rounded())
                                            .foregroundStyle(adherenceColor(medication.adherenceThisWeek))
                                    }

                                    HStack(spacing: 10) {
                                        Button("Taken") {
                                            logDose(medication, status: .taken)
                                        }
                                        .buttonStyle(MedActionStyle(color: AppTheme.softMint))

                                        Button("Skipped") {
                                            logDose(medication, status: .skipped)
                                        }
                                        .buttonStyle(MedActionStyle(color: AppTheme.warmCoral.opacity(0.8)))
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .padding(.bottom, 120)
            .navigationTitle("Medications")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddMedication = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .disabled(parents.isEmpty)
                }
            }
        }
        .sheet(isPresented: $showAddMedication) {
            AddMedicationView()
        }
    }

    private func logDose(_ medication: Medication, status: MedicationStatus) {
        let log = MedicationLog(status: status, medication: medication)
        modelContext.insert(log)
    }

    private func adherenceColor(_ value: Double) -> Color {
        if value >= 0.8 { return AppTheme.softMint }
        if value >= 0.5 { return .yellow }
        return AppTheme.warmCoral
    }
}

struct MedicationRow: View {
    let medication: Medication
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "pills.fill")
                .foregroundStyle(AppTheme.warmCoral)
                .frame(width: compact ? 20 : 28)

            VStack(alignment: .leading, spacing: 2) {
                if !compact {
                    Text(medication.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                }
                Text("\(medication.dosage) · \(medication.frequency)")
                    .font(compact ? .caption : .caption)
                    .foregroundStyle(.white.opacity(0.55))
            }

            Spacer()

            Text(reminderText)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.45))
        }
    }

    private var reminderText: String {
        medication.reminderHours
            .map { String(format: "%02d:00", $0) }
            .joined(separator: ", ")
    }
}

struct MedActionStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(color.opacity(configuration.isPressed ? 0.6 : 0.35))
            )
    }
}

#Preview {
    MedicationsView()
        .modelContainer(SampleData.previewContainer)
}
