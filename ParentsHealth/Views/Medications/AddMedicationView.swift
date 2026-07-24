import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct AddMedicationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var parentStore: SelectedParentStore
    @Query(sort: \ParentProfile.name) private var parents: [ParentProfile]

    var medication: Medication?

    @State private var selectedParentID: UUID?
    @State private var name = ""
    @State private var dosage = ""
    @State private var frequency: MedicationFrequency = .daily
    @State private var morningReminder = true
    @State private var eveningReminder = false
    @State private var isActive = true
    @State private var scheduleWeekday = Calendar.current.component(.weekday, from: Date())
    @State private var scheduleDayOfMonth = min(Calendar.current.component(.day, from: Date()), 28)
    @State private var photoItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var isScanning = false
    @State private var scanMessage: String?

    private var isEditing: Bool { medication != nil }

    var body: some View {
        NavigationStack {
            Form {
                if !isEditing {
                    Section("Scan label") {
                        PhotosPicker(selection: $photoItem, matching: .images) {
                            Label(
                                isScanning ? "Reading label…" : "Choose photo of bottle / label",
                                systemImage: "text.viewfinder"
                            )
                        }
                        .disabled(isScanning)

                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            Button {
                                showCamera = true
                            } label: {
                                Label("Take photo", systemImage: "camera.fill")
                            }
                            .disabled(isScanning)
                        }

                        if let scanMessage {
                            Text(scanMessage)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

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
                        ForEach(MedicationFrequency.allCases) { kind in
                            Text(kind.rawValue).tag(kind)
                        }
                    }
                    if frequency.needsWeekdayPicker {
                        Picker("Day of week", selection: $scheduleWeekday) {
                            ForEach(1...7, id: \.self) { weekday in
                                Text(Calendar.current.weekdaySymbols[weekday - 1]).tag(weekday)
                            }
                        }
                    }
                    if frequency.needsDayOfMonthPicker {
                        Picker("Day of month", selection: $scheduleDayOfMonth) {
                            ForEach(1...28, id: \.self) { day in
                                Text("Day \(day)").tag(day)
                            }
                        }
                    }
                    if isEditing {
                        Toggle("Active", isOn: $isActive)
                    }
                }

                if frequency.showsDailyReminderToggles {
                    Section(reminderSectionTitle) {
                        Toggle("Morning (8:00)", isOn: $morningReminder)
                        Toggle("Evening (20:00)", isOn: $eveningReminder)
                    }
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
            .onAppear(perform: loadExisting)
            .onChange(of: frequency) { _, newValue in
                applyFrequencyDefaults(newValue)
            }
            .onChange(of: photoItem) { _, item in
                guard let item else { return }
                Task { await scanPhotoItem(item) }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraImagePicker { image in
                    Task { await scanImage(image) }
                }
                .ignoresSafeArea()
            }
        }
    }

    private var reminderSectionTitle: String {
        switch frequency {
        case .weekly: return "Reminder time (weekly)"
        case .monthly: return "Reminder time (monthly)"
        default: return "Reminders"
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
            frequency = medication.frequencyKind
            morningReminder = medication.reminderHours.contains(8)
            eveningReminder = medication.reminderHours.contains(20)
            isActive = medication.isActive
            scheduleWeekday = medication.scheduleWeekday
            scheduleDayOfMonth = medication.scheduleDayOfMonth
        } else {
            parentStore.ensureSelection(from: parents)
            selectedParentID = parentStore.parentID ?? parents.first?.id
            applyFrequencyDefaults(frequency)
        }
    }

    private func applyFrequencyDefaults(_ kind: MedicationFrequency) {
        guard medication == nil else { return }
        switch kind {
        case .twiceDaily:
            morningReminder = true
            eveningReminder = true
        case .asNeeded:
            morningReminder = false
            eveningReminder = false
        case .daily, .weekly, .monthly:
            if !morningReminder && !eveningReminder {
                morningReminder = true
            }
        }
    }

    private func scanPhotoItem(_ item: PhotosPickerItem) async {
        isScanning = true
        defer { isScanning = false }
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                scanMessage = "Could not read that photo."
                return
            }
            await scanImage(image)
        } catch {
            scanMessage = error.localizedDescription
        }
    }

    private func scanImage(_ image: UIImage) async {
        isScanning = true
        defer { isScanning = false }
        do {
            let parsed = try await MedicationOCRService.parse(from: image)
            if !parsed.name.isEmpty { name = parsed.name }
            if !parsed.dosage.isEmpty { dosage = parsed.dosage }
            scanMessage = parsed.name.isEmpty && parsed.dosage.isEmpty
                ? "No medication details found — enter them manually."
                : "Filled from label. Review before saving."
            FeedbackService.success()
        } catch {
            scanMessage = error.localizedDescription
        }
    }

    private func save() {
        guard let parent = parents.first(where: { $0.id == selectedParentID }) else { return }

        var hours: [Int] = []
        if frequency != .asNeeded {
            if morningReminder { hours.append(8) }
            if eveningReminder { hours.append(20) }
            if hours.isEmpty { hours = frequency.defaultReminderHours }
        }

        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedDosage = dosage.trimmingCharacters(in: .whitespaces)

        if let medication {
            medication.name = trimmedName
            medication.dosage = trimmedDosage
            medication.frequency = frequency.rawValue
            medication.reminderHours = hours
            medication.isActive = isActive
            medication.scheduleWeekday = scheduleWeekday
            medication.scheduleDayOfMonth = scheduleDayOfMonth
            rescheduleNotifications(for: medication)
        } else {
            let newMedication = Medication(
                name: trimmedName,
                dosage: trimmedDosage,
                frequency: frequency.rawValue,
                reminderHours: hours,
                scheduleWeekday: scheduleWeekday,
                scheduleDayOfMonth: scheduleDayOfMonth,
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
