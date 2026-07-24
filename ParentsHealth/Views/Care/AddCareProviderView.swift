import SwiftUI
import SwiftData

struct AddCareProviderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let parent: ParentProfile
    var provider: CareProvider?

    @State private var name = ""
    @State private var specialty = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var clinic = ""
    @State private var notes = ""

    private var isEditing: Bool { provider != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Doctor") {
                    TextField("Name", text: $name)
                    TextField("Specialty (e.g. Cardiology)", text: $specialty)
                    TextField("Clinic / hospital", text: $clinic)
                }
                Section("Contact") {
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                }
                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(isEditing ? "Edit Doctor" : "Add Doctor")
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
            .onAppear(perform: loadExisting)
        }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func loadExisting() {
        guard let provider else { return }
        name = provider.name
        specialty = provider.specialty
        phone = provider.phone
        email = provider.email
        clinic = provider.clinic
        notes = provider.notes
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if let provider {
            provider.name = trimmedName
            provider.specialty = specialty.trimmingCharacters(in: .whitespacesAndNewlines)
            provider.phone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
            provider.email = email.trimmingCharacters(in: .whitespacesAndNewlines)
            provider.clinic = clinic.trimmingCharacters(in: .whitespacesAndNewlines)
            provider.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            let created = CareProvider(
                name: trimmedName,
                specialty: specialty.trimmingCharacters(in: .whitespacesAndNewlines),
                phone: phone.trimmingCharacters(in: .whitespacesAndNewlines),
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                clinic: clinic.trimmingCharacters(in: .whitespacesAndNewlines),
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                parent: parent
            )
            modelContext.insert(created)
        }
        FeedbackService.success()
        dismiss()
    }
}
