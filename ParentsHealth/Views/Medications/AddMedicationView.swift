import SwiftUI
import SwiftData

struct AddMedicationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var parentStore: SelectedParentStore
    @Query(sort: \ParentProfile.name) private var parents: [ParentProfile]

    var medication: Medication?

    @State private var selectedParentID: UUID?
    @State private var name = ""
    @State private var dosage = ""
    @State private var frequency = "Daily"
    @State private var morningReminder = true
    @State private var eveningReminder = true
    @State private var isActive = true

    private let frequencies = ["Daily", "Twice daily", "Weekly", "As needed"]

    private var isEditing: Bool { medication != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Parent") {
                    Picker("Parent", selection: $selectedParentID) {
                        ForEach(parents) { parent in
                            Text(parent.name).tag(Optional(parent.id))
                        }
                    }
                    .disabled(isEditing)
                }

                Section("Medication") {
                    TextField("Name", text: $name)
                    TextField("Dosage (e.g. 10mg)", text: $dosage)
                    Picker("Frequency", selection: $frequency) {
                        ForEach(frequencies, id: \.self) { Text($0) }
                    }
                    if isEditing {
                        Toggle("Active", isOn: $isActive)
                    }
                }

                Section("Reminders") {
                    Toggle("Morning (8:00)", isOn: $morningReminder)
                    Toggle("Evening (20:00)", isOn: $eveningReminder)
                }
            }
            .navigationTitle(isEditing ? "Edit Medication" : "Add Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
            .onAppear {
                loadExisting()
            }
        }
    }

    private var canSave: Bool {
        selectedParentID != nil &&
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !dosage.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func loadExisting() {
        if let medication {
            selectedParentID = medication.parent?.id
            name = medication.name
            dosage = medication.dosage
            frequency = medication.frequency
            morningReminder = medication.reminderHours.contains(8)
            eveningReminder = medication.reminderHours.contains(20)
            isActive = medication.isActive
        } else {
            parentStore.ensureSelection(from: parents)
            selectedParentID = parentStore.parentID ?? parents.first?.id
        }
    }

    private func save() {
        guard let parent = parents.first(where: { $0.id == selectedParentID }) else { return }

        var hours: [Int] = []
        if morningReminder { hours.append(8) }
        if eveningReminder { hours.append(20) }

        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedDosage = dosage.trimmingCharacters(in: .whitespaces)

        if let medication {
            medication.name = trimmedName
            medication.dosage = trimmedDosage
            medication.frequency = frequency
            medication.reminderHours = hours
            medication.isActive = isActive
            rescheduleNotifications(for: medication)
        } else {
            let newMedication = Medication(
                name: trimmedName,
                dosage: trimmedDosage,
                frequency: frequency,
                reminderHours: hours,
                parent: parent
            )
            modelContext.insert(newMedication)
            parentStore.parentID = parent.id
            rescheduleNotifications(for: newMedication)
        }

        FeedbackService.success()
        dismiss()
    }

    private func rescheduleNotifications(for medication: Medication) {
        guard AppSettings.notificationsEnabled else { return }
        Task {
            if !NotificationService.shared.isAuthorized {
                _ = await NotificationService.shared.requestAuthorization()
            }
            await NotificationService.shared.scheduleMedicationReminders(for: medication)
        }
    }
}

#Preview {
    AddMedicationView()
        .environmentObject(SelectedParentStore())
        .modelContainer(SampleData.previewContainer)
}
