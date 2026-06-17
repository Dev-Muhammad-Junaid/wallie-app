import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ParentProfile.name) private var parents: [ParentProfile]

    @StateObject private var notifications = NotificationService.shared
    @StateObject private var healthKit = HealthKitService.shared

    @State private var healthKitEnabled = AppSettings.healthKitEnabled
    @State private var weeklySummaryEnabled = AppSettings.weeklySummaryEnabled
    @State private var notificationsEnabled = AppSettings.notificationsEnabled
    @State private var selectedParentForExport: UUID?
    @State private var selectedParentForSync: UUID?
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var statusMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Notifications") {
                    Toggle("Medication Reminders", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { _, enabled in
                            AppSettings.notificationsEnabled = enabled
                            Task { await updateNotifications(enabled: enabled) }
                        }

                    Toggle("Weekly Health Summary", isOn: $weeklySummaryEnabled)
                        .onChange(of: weeklySummaryEnabled) { _, enabled in
                            AppSettings.weeklySummaryEnabled = enabled
                            Task { await updateWeeklySummary(enabled: enabled) }
                        }

                    HStack {
                        Text("Status")
                        Spacer()
                        Text(notifications.isAuthorized ? "Authorized" : "Not authorized")
                            .foregroundStyle(.secondary)
                    }

                    if !notifications.isAuthorized {
                        Button("Enable Notifications") {
                            Task {
                                let granted = await notifications.requestAuthorization()
                                if granted {
                                    await notifications.rescheduleAll(parents: parents)
                                }
                            }
                        }
                    }
                }

                Section("HealthKit") {
                    Toggle("Sync from HealthKit", isOn: $healthKitEnabled)
                        .disabled(!healthKit.isAvailable)
                        .onChange(of: healthKitEnabled) { _, enabled in
                            AppSettings.healthKitEnabled = enabled
                        }

                    if healthKit.isAvailable {
                        Picker("Sync for", selection: $selectedParentForSync) {
                            ForEach(parents) { parent in
                                Text(parent.name).tag(Optional(parent.id))
                            }
                        }

                        Button("Sync Last 14 Days") {
                            Task { await syncHealthKit() }
                        }
                        .disabled(!healthKitEnabled || selectedParentForSync == nil)

                        if let lastSync = healthKit.lastSyncDate {
                            Text("Last sync: \(lastSync.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("HealthKit is not available on this device.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Export Report") {
                    Picker("Parent", selection: $selectedParentForExport) {
                        ForEach(parents) { parent in
                            Text(parent.name).tag(Optional(parent.id))
                        }
                    }

                    Button("Share Health Report") {
                        exportReport()
                    }
                    .disabled(selectedParentForExport == nil)
                }

                Section("Privacy") {
                    Label("All data stays on this device", systemImage: "lock.shield.fill")
                    Label("Lab analysis runs on-device", systemImage: "cpu")
                    Label("No cloud sync or analytics", systemImage: "icloud.slash")
                }

                if !statusMessage.isEmpty {
                    Section {
                        Text(statusMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: shareItems)
            }
            .task {
                await notifications.refreshAuthorizationStatus()
                selectedParentForExport = parents.first?.id
                selectedParentForSync = parents.first?.id
            }
        }
    }

    private func updateNotifications(enabled: Bool) async {
        if enabled {
            let granted = notifications.isAuthorized || await notifications.requestAuthorization()
            if granted {
                await notifications.rescheduleAll(parents: parents)
                statusMessage = "Medication reminders scheduled."
            }
        }
    }

    private func updateWeeklySummary(enabled: Bool) async {
        if enabled, notifications.isAuthorized {
            await notifications.scheduleWeeklySummary(for: parents)
            statusMessage = "Weekly summary scheduled for Sundays at 9 AM."
        }
    }

    private func syncHealthKit() async {
        guard let parent = parents.first(where: { $0.id == selectedParentForSync }) else { return }
        do {
            if !healthKit.isAuthorized {
                try await healthKit.requestAuthorization()
            }
            let count = try await healthKit.syncMetrics(for: parent, context: modelContext)
            statusMessage = "Imported \(count) readings from HealthKit."
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    private func exportReport() {
        guard let parent = parents.first(where: { $0.id == selectedParentForExport }) else { return }
        shareItems = ReportExportService.shareItems(for: parent)
        showShareSheet = true
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView()
        .modelContainer(SampleData.previewContainer)
}
