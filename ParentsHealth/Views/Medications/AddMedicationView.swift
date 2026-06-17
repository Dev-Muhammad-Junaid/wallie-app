import SwiftUI
import SwiftData

struct AddMedicationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ParentProfile.name) private var parents: [ParentProfile]

    @State private var selectedParentID: UUID?
    @State private var name = ""
    @State private var dosage = ""
    @State private var frequency = "Daily"
    @State private var morningReminder = true
    @State private var eveningReminder = true

    private let frequencies = ["Daily", "Twice daily", "Weekly", "As needed"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Parent") {
                    Picker("Parent", selection: $selectedParentID) {
                        ForEach(parents) { parent in
                            Text(parent.name).tag(Optional(parent.id))
                        }
                    }
                }

                Section("Medication") {
                    TextField("Name", text: $name)
                    TextField("Dosage (e.g. 10mg)", text: $dosage)
                    Picker("Frequency", selection: $frequency) {
                        ForEach(frequencies, id: \.self) { Text($0) }
                    }
                }

                Section("Reminders") {
                    Toggle("Morning (8:00)", isOn: $morningReminder)
                    Toggle("Evening (20:00)", isOn: $eveningReminder)
                }
            }
            .navigationTitle("Add Medication")
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
                selectedParentID = parents.first?.id
            }
        }
    }

    private var canSave: Bool {
        selectedParentID != nil &&
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !dosage.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func save() {
        guard let parent = parents.first(where: { $0.id == selectedParentID }) else { return }

        var hours: [Int] = []
        if morningReminder { hours.append(8) }
        if eveningReminder { hours.append(20) }

        let medication = Medication(
            name: name.trimmingCharacters(in: .whitespaces),
            dosage: dosage.trimmingCharacters(in: .whitespaces),
            frequency: frequency,
            reminderHours: hours,
            parent: parent
        )
        modelContext.insert(medication)
        dismiss()
    }
}

#Preview {
    AddMedicationView()
        .modelContainer(SampleData.previewContainer)
}
