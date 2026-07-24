import SwiftUI
import SwiftData

struct AddAppointmentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let parent: ParentProfile
    var appointment: Appointment?

    @State private var title = ""
    @State private var scheduledAt = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var location = ""
    @State private var notes = ""
    @State private var selectedProviderID: UUID?
    @State private var reminderMinutes = 60

    private let reminderOptions: [(label: String, minutes: Int)] = [
        ("None", 0),
        ("1 hour before", 60),
        ("1 day before", 60 * 24),
        ("2 days before", 60 * 24 * 2),
        ("1 week before", 60 * 24 * 7)
    ]

    private var isEditing: Bool { appointment != nil }

    private var providers: [CareProvider] {
        parent.careProviders.sorted { $0.name < $1.name }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Visit") {
                    TextField("Title (optional)", text: $title)
                    DatePicker("Date & time", selection: $scheduledAt)
                    TextField("Location", text: $location)
                }

                Section("Doctor") {
                    Picker("Provider", selection: $selectedProviderID) {
                        Text("None").tag(Optional<UUID>.none)
                        ForEach(providers, id: \.id) { provider in
                            Text(provider.name).tag(Optional(provider.id))
                        }
                    }
                }

                Section("Reminder") {
                    Picker("Notify", selection: $reminderMinutes) {
                        ForEach(reminderOptions, id: \.minutes) { option in
                            Text(option.label).tag(option.minutes)
                        }
                    }
                }

                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(isEditing ? "Edit Appointment" : "Add Appointment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .onAppear(perform: loadExisting)
        }
    }

    private func loadExisting() {
        guard let appointment else {
            selectedProviderID = providers.first?.id
            return
        }
        title = appointment.title
        scheduledAt = appointment.scheduledAt
        location = appointment.location
        notes = appointment.notes
        reminderMinutes = appointment.reminderMinutesBefore
        selectedProviderID = appointment.provider?.id
    }

    private func save() {
        let provider = providers.first { $0.id == selectedProviderID }
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        if let appointment {
            appointment.title = trimmedTitle
            appointment.scheduledAt = scheduledAt
            appointment.location = location.trimmingCharacters(in: .whitespacesAndNewlines)
            appointment.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            appointment.reminderMinutesBefore = reminderMinutes
            appointment.provider = provider
            reschedule(appointment)
        } else {
            let created = Appointment(
                title: trimmedTitle,
                scheduledAt: scheduledAt,
                location: location.trimmingCharacters(in: .whitespacesAndNewlines),
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                reminderMinutesBefore: reminderMinutes,
                parent: parent,
                provider: provider
            )
            modelContext.insert(created)
            reschedule(created)
        }

        FeedbackService.success()
        dismiss()
    }

    private func reschedule(_ appointment: Appointment) {
        guard AppSettings.notificationsEnabled else { return }
        Task {
            if !NotificationService.shared.isAuthorized {
                _ = await NotificationService.shared.requestAuthorization()
            }
            await NotificationService.shared.scheduleAppointmentReminder(for: appointment)
        }
    }
}
