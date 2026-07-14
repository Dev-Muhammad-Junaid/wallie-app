import SwiftUI
import SwiftData

struct MedicationsView: View {
    @Binding var showAddMedication: Bool

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var parentStore: SelectedParentStore
    @Query(sort: \ParentProfile.name) private var parents: [ParentProfile]
    @State private var medicationToEdit: Medication?
    @State private var medicationToDelete: Medication?

    init(showAddMedication: Binding<Bool> = .constant(false)) {
        _showAddMedication = showAddMedication
    }

    private var filteredMedications: [(ParentProfile, Medication)] {
        guard let parent = parentStore.parent(from: parents) else { return [] }
        return parent.medications.map { (parent, $0) }
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                    ParentChipPicker(parents: parents, selectedParentID: $parentStore.parentID)

                    if parents.isEmpty {
                        emptyParentsCard
                    } else if filteredMedications.isEmpty {
                        emptyMedsCard
                    } else {
                        LazyVStack(spacing: 14) {
                            ForEach(filteredMedications, id: \.1.id) { parent, medication in
                                medicationCard(parent: parent, medication: medication)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .scrollBottomClearance()
            }
            .navigationTitle("Medications")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .sheet(item: $medicationToEdit) { medication in
            AddMedicationView(medication: medication)
                .environmentObject(parentStore)
        }
        .alert("Remove medication?", isPresented: Binding(
            get: { medicationToDelete != nil },
            set: { if !$0 { medicationToDelete = nil } }
        )) {
            Button("Remove", role: .destructive) {
                if let medication = medicationToDelete {
                    confirmDelete(medication)
                }
                medicationToDelete = nil
            }
            Button("Cancel", role: .cancel) { medicationToDelete = nil }
        } message: {
            Text("This removes the medication and its dose history.")
        }
        .onAppear {
            parentStore.ensureSelection(from: parents)
        }
    }

    private var emptyParentsCard: some View {
        GlassCard {
            VStack(spacing: 12) {
                Image(systemName: "person.2.badge.plus")
                    .font(.largeTitle)
                    .foregroundStyle(AppTheme.softMint)
                Text("Add a parent first")
                    .font(.sectionHeadline)
                    .foregroundStyle(.white)
                Text("Medications are tracked per parent profile.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        }
    }

    private var emptyMedsCard: some View {
        GlassCard {
            VStack(spacing: 14) {
                Image(systemName: "pills.fill")
                    .font(.largeTitle)
                    .foregroundStyle(AppTheme.warmCoral)
                Text("No medications yet")
                    .font(.sectionHeadline)
                    .foregroundStyle(.white)
                Text("Tap the button below to add medications for \(parentStore.parent(from: parents)?.name ?? "this parent").")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                Button("Add medication") { showAddMedication = true }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.deepTeal)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
        }
    }

    private func medicationCard(parent: ParentProfile, medication: Medication) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(medication.name)
                        .font(.sectionHeadline)
                        .foregroundStyle(.white)
                    Spacer()
                    if !medication.isActive {
                        Text("Inactive")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.6))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.white.opacity(0.12)))
                    }
                }

                MedicationRow(medication: medication)

                HStack {
                    Text("Adherence this week")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                    Spacer()
                    Text("\(Int(medication.adherenceThisWeek * 100))%")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundStyle(adherenceColor(medication.adherenceThisWeek))
                }

                if medication.isActive {
                    doseSlotsSection(medication)
                }

                HStack(spacing: 10) {
                    Button("Edit") { medicationToEdit = medication }
                        .buttonStyle(MedActionStyle(color: AppTheme.deepTeal.opacity(0.8)))

                    Button("Remove") { medicationToDelete = medication }
                        .buttonStyle(MedActionStyle(color: Color.white.opacity(0.2)))
                }
            }
        }
        .contextMenu {
            Button("Edit") { medicationToEdit = medication }
            Button("Remove", role: .destructive) { medicationToDelete = medication }
        }
    }

    @ViewBuilder
    private func doseSlotsSection(_ medication: Medication) -> some View {
        let hours = medication.reminderHours.sorted()
        if hours.isEmpty {
            HStack(spacing: 10) {
                Button("Taken") { logDose(medication, status: .taken, hour: Calendar.current.component(.hour, from: Date())) }
                    .buttonStyle(MedActionStyle(color: AppTheme.softMint))
                Button("Skipped") { logDose(medication, status: .skipped, hour: Calendar.current.component(.hour, from: Date())) }
                    .buttonStyle(MedActionStyle(color: AppTheme.warmCoral.opacity(0.8)))
            }
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text("Today's doses")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.55))

                ForEach(hours, id: \.self) { hour in
                    doseSlotRow(medication: medication, hour: hour)
                }
            }
        }
    }

    private func doseSlotRow(medication: Medication, hour: Int) -> some View {
        let status = medication.todayLog(forHour: hour)?.status
        return HStack(spacing: 10) {
            Text(String(format: "%02d:00", hour))
                .font(.caption.weight(.semibold).monospacedDigit())
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 48, alignment: .leading)

            if let status {
                Label(
                    status == .taken ? "Taken" : (status == .skipped ? "Skipped" : "Missed"),
                    systemImage: status == .taken ? "checkmark.circle.fill" : "xmark.circle"
                )
                .font(.caption)
                .foregroundStyle(status == .taken ? AppTheme.softMint : AppTheme.warmCoral.opacity(0.9))
                Spacer()
                Button("Undo") {
                    undoDose(medication, hour: hour)
                }
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.55))
            } else {
                Spacer()
                Button("Taken") { logDose(medication, status: .taken, hour: hour) }
                    .buttonStyle(MedActionStyle(color: AppTheme.softMint))
                    .frame(maxWidth: 100)
                Button("Skip") { logDose(medication, status: .skipped, hour: hour) }
                    .buttonStyle(MedActionStyle(color: AppTheme.warmCoral.opacity(0.8)))
                    .frame(maxWidth: 80)
            }
        }
    }

    private func confirmDelete(_ medication: Medication) {
        Task {
            await NotificationService.shared.cancelMedicationReminders(for: medication)
        }
        modelContext.delete(medication)
        FeedbackService.warning()
    }

    private func logDose(_ medication: Medication, status: MedicationStatus, hour: Int) {
        let calendar = Calendar.current
        let now = Date()
        let day = calendar.startOfDay(for: now)
        let stamped = calendar.date(bySettingHour: hour, minute: min(calendar.component(.minute, from: now), 59), second: 0, of: day) ?? now

        if let existing = medication.todayLog(forHour: hour) {
            existing.status = status
            existing.takenAt = stamped
        } else {
            let log = MedicationLog(status: status, takenAt: stamped, medication: medication)
            modelContext.insert(log)
        }
        FeedbackService.success()
    }

    private func undoDose(_ medication: Medication, hour: Int) {
        if let existing = medication.todayLog(forHour: hour) {
            modelContext.delete(existing)
            FeedbackService.lightTap()
        }
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
                    .font(.caption)
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
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

#Preview {
    MedicationsView()
        .environmentObject(SelectedParentStore())
        .modelContainer(SampleData.previewContainer)
}
