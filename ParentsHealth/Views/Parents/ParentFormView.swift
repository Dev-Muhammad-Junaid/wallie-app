import SwiftUI
import SwiftData

struct ParentFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var parent: ParentProfile?

    @State private var name = ""
    @State private var dateOfBirth = Calendar.current.date(byAdding: .year, value: -70, to: Date()) ?? Date()
    @State private var bloodType = "O+"
    @State private var conditionsText = ""
    @State private var emergencyContact = ""
    @State private var emergencyPhone = ""
    @State private var notes = ""

    private let bloodTypes = ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Full Name", text: $name)
                    DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)
                    Picker("Blood Type", selection: $bloodType) {
                        ForEach(bloodTypes, id: \.self) { Text($0) }
                    }
                }

                Section("Health") {
                    TextField("Conditions (comma separated)", text: $conditionsText, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Emergency") {
                    TextField("Contact Name", text: $emergencyContact)
                    TextField("Phone Number", text: $emergencyPhone)
                        .keyboardType(.phonePad)
                }

                Section("Notes") {
                    TextField("Additional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(parent == nil ? "Add Parent" : "Edit Parent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: loadExisting)
        }
    }

    private func loadExisting() {
        guard let parent else { return }
        name = parent.name
        dateOfBirth = parent.dateOfBirth
        bloodType = parent.bloodType
        conditionsText = parent.conditions.joined(separator: ", ")
        emergencyContact = parent.emergencyContact
        emergencyPhone = parent.emergencyPhone
        notes = parent.notes
    }

    private func save() {
        let conditions = conditionsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        if let parent {
            parent.name = name.trimmingCharacters(in: .whitespaces)
            parent.dateOfBirth = dateOfBirth
            parent.bloodType = bloodType
            parent.conditions = conditions
            parent.emergencyContact = emergencyContact
            parent.emergencyPhone = emergencyPhone
            parent.notes = notes
        } else {
            let newParent = ParentProfile(
                name: name.trimmingCharacters(in: .whitespaces),
                dateOfBirth: dateOfBirth,
                bloodType: bloodType,
                conditions: conditions,
                emergencyContact: emergencyContact,
                emergencyPhone: emergencyPhone,
                notes: notes
            )
            modelContext.insert(newParent)
        }
        dismiss()
    }
}

#Preview {
    ParentFormView()
        .modelContainer(SampleData.previewContainer)
}
