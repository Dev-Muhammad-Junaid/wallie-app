import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var parentStore: SelectedParentStore
    @Query(sort: \ParentProfile.name) private var parents: [ParentProfile]

    @StateObject private var notifications = NotificationService.shared
    @StateObject private var healthKit = HealthKitService.shared

    @State private var healthKitEnabled = AppSettings.healthKitEnabled
    @State private var notificationsEnabled = AppSettings.notificationsEnabled
    @State private var healthAlertsEnabled = AppSettings.healthAlertsEnabled
    @State private var weeklySummaryEnabled = AppSettings.weeklySummaryEnabled
    @State private var selectedParentForExport: UUID?
    @State private var selectedParentForSync: UUID?
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var statusMessage = ""
    @State private var isSyncingHealthKit = false
    @State private var useRemoteLabAPI = AppSettings.useRemoteLabAPI
    @State private var labAPIEndpoint = AppSettings.labAPIEndpoint ?? ""
    @State private var labAPIKey = AppSettings.labAPIKey
    @State private var showDemoDataConfirm = false
    @State private var isLoadingDemoData = false
    @State private var iCloudSyncEnabled = AppSettings.iCloudSyncEnabled
    @State private var siriSpotlightIndexingEnabled = AppSettings.siriSpotlightIndexingEnabled
    @State private var showOnboarding = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label("On-device by default", systemImage: "lock.shield")
                    Text("Lab photos are OCR'd on your phone. When you add an API endpoint below, analysis tries your server first and falls back to on-device parsing.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Lab Report AI")
                }

                Section("Remote AI API (optional)") {
                    Toggle("Use API when available", isOn: $useRemoteLabAPI)
                        .onChange(of: useRemoteLabAPI) { _, value in
                            AppSettings.useRemoteLabAPI = value
                        }

                    TextField("API Endpoint URL", text: $labAPIEndpoint)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .onChange(of: labAPIEndpoint) { _, value in
                            AppSettings.labAPIEndpoint = value.isEmpty ? nil : value
                        }

                    SecureField("API Key (optional)", text: $labAPIKey)
                        .onChange(of: labAPIKey) { _, value in
                            AppSettings.labAPIKey = value
                        }

                    Text("Expected JSON: { results: [{ testKey, testName, value, unit, referenceRange, isAbnormal }], labDate?, insights? }")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Section("Notifications") {
                    Toggle("Medication Reminders", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { _, enabled in
                            AppSettings.notificationsEnabled = enabled
                            Task { await updateNotifications(enabled: enabled) }
                        }

                    Toggle("Out-of-Range Health Alerts", isOn: $healthAlertsEnabled)
                        .onChange(of: healthAlertsEnabled) { _, enabled in
                            AppSettings.healthAlertsEnabled = enabled
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

                Section("Demo Data") {
                    Button {
                        showDemoDataConfirm = true
                    } label: {
                        if isLoadingDemoData {
                            HStack {
                                ProgressView()
                                Text("Loading year of data…")
                            }
                        } else {
                            Text("Load 1-Year Sample Data")
                                .foregroundStyle(AppTheme.warmCoral)
                        }
                    }
                    .disabled(isLoadingDemoData)
                    Text("Replaces all profiles with Margaret & Robert Chen — 12 months of vitals, quarterly labs, medications, and adherence logs.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Section("Data Overview") {
                    if parents.isEmpty {
                        Text("Add a parent profile first, then log vitals, import labs, or sync HealthKit.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Profile", selection: $selectedParentForSync) {
                            ForEach(parents) { parent in
                                Text(parent.name).tag(Optional(parent.id))
                            }
                        }

                        if let parent = parents.first(where: { $0.id == selectedParentForSync }) {
                            let overview = parent.dataOverview
                            LabeledContent("Vitals logged", value: "\(overview.vitalsTotal)")
                            LabeledContent("Last 14 days", value: "\(overview.vitalsLast14Days)")
                            LabeledContent("From HealthKit", value: "\(overview.vitalsFromHealthKit)")
                            LabeledContent("Lab reports", value: "\(overview.labReports)")
                            LabeledContent("Lab values", value: "\(overview.labValues)")
                            LabeledContent("Medications", value: "\(overview.medications)")
                            LabeledContent("Last vital", value: overview.lastVitalLabel)
                            LabeledContent("Last lab", value: overview.lastLabLabel)

                            Text("Verify: Home shows recent vitals · Charts plots trends · Labs lists saved reports · Export shares a full snapshot.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
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

                        Button {
                            Task { await syncHealthKit() }
                        } label: {
                            if isSyncingHealthKit {
                                HStack {
                                    ProgressView()
                                    Text("Syncing…")
                                }
                            } else {
                                Text("Sync Last 14 Days")
                            }
                        }
                        .disabled(!healthKitEnabled || selectedParentForSync == nil || isSyncingHealthKit)

                        if healthKit.hasRequestedAccess {
                            Text("If no data imports, open the Health app → Sharing → Apps → ParentsHealth and allow read access to vitals.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        if !healthKit.lastSyncMessage.isEmpty {
                            Text(healthKit.lastSyncMessage)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

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
                    if parents.isEmpty {
                        Text("Add a parent profile to export a health report.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
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
                }

                Section("Siri & Spotlight") {
                    Toggle("Index names in Spotlight", isOn: $siriSpotlightIndexingEnabled)
                        .onChange(of: siriSpotlightIndexingEnabled) { _, enabled in
                            AppSettings.siriSpotlightIndexingEnabled = enabled
                            CareSpotlightIndexer.refresh(parents: parents)
                            CareAppShortcuts.updateAppShortcutParameters()
                            statusMessage = enabled
                                ? "Parent names, medication names, and visits can appear in Search."
                                : "Search indexing is off. Siri shortcuts still work."
                        }
                    Text(siriSpotlightCaption)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Section("Family Sync") {
                    Toggle("iCloud Sync", isOn: $iCloudSyncEnabled)
                        .onChange(of: iCloudSyncEnabled) { _, enabled in
                            AppSettings.iCloudSyncEnabled = enabled
                            statusMessage = "Relaunch the app to \(enabled ? "enable" : "disable") iCloud sync."
                        }
                    Text("Keeps parents, meds, labs, doctors, and appointments in sync on every device signed into the same iCloud account — so siblings sharing one Apple ID (or a shared family device login) see the same care data.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Section("Privacy") {
                    Label("Health data stored with SwiftData", systemImage: "lock.shield.fill")
                    Label("Lab & medication OCR runs on-device", systemImage: "cpu")
                    Label(
                        siriSpotlightIndexingEnabled
                            ? "Spotlight may show names you opted in"
                            : "Siri shortcuts work without sharing names to Search",
                        systemImage: siriSpotlightIndexingEnabled ? "sparkles" : "waveform"
                    )
                    Label(
                        iCloudSyncEnabled
                            ? "Optional iCloud sync across your devices"
                            : "Cloud sync is off on this device",
                        systemImage: iCloudSyncEnabled ? "icloud.fill" : "icloud.slash"
                    )
                }

                if !statusMessage.isEmpty {
                    Section {
                        Text(statusMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("About") {
                    Button("Replay app tour") {
                        showOnboarding = true
                    }
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.2")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(HealthGradientBackground())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: shareItems)
            }
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingView {
                    showOnboarding = false
                }
            }
            .alert("Load sample data?", isPresented: $showDemoDataConfirm) {
                Button("Replace All Data", role: .destructive) {
                    loadDemoData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This deletes your current parents, vitals, labs, and medications, then loads one year of demo data.")
            }
            .task {
                await notifications.refreshAuthorizationStatus()
                selectedParentForExport = parentStore.parentID ?? parents.first?.id
                selectedParentForSync = parentStore.parentID ?? parents.first?.id
            }
            .onChange(of: parentStore.parentID) { _, id in
                if let id {
                    selectedParentForExport = id
                    selectedParentForSync = id
                }
            }
        }
    }

    private var siriSpotlightCaption: String {
        let shortcuts = "Siri on iOS 17 can still run phrases like “What’s due today in ParentsHealth” from Shortcuts — that does not index your health records."
        if #available(iOS 18.0, *) {
            return "Off by default. When on, only parent names, medication names, and visit titles go to Spotlight so newer Siri can find them. Labs, vitals, and notes stay in the app. \(shortcuts)"
        }
        return "Off by default. This iOS version can list names in Spotlight Search when you turn this on. Labs, vitals, and notes stay in the app. \(shortcuts)"
    }

    private func updateNotifications(enabled: Bool) async {
        if enabled {
            var granted = notifications.isAuthorized
            if !granted {
                granted = await notifications.requestAuthorization()
            }
            if granted {
                await notifications.rescheduleAll(parents: parents)
                statusMessage = "Medication reminders scheduled."
            }
        } else {
            await notifications.cancelAllScheduledNotifications()
            statusMessage = "All scheduled reminders cancelled."
        }
    }

    private func updateWeeklySummary(enabled: Bool) async {
        if enabled, notifications.isAuthorized {
            await notifications.scheduleWeeklySummary(for: parents)
            statusMessage = "Weekly summary scheduled for Sundays at 9 AM."
        } else {
            await notifications.cancelWeeklySummary()
            statusMessage = "Weekly summary cancelled."
        }
    }

    private func syncHealthKit() async {
        guard let parent = parents.first(where: { $0.id == selectedParentForSync }) else { return }
        isSyncingHealthKit = true
        defer { isSyncingHealthKit = false }
        do {
            if !healthKit.hasRequestedAccess {
                try await healthKit.requestAuthorization()
            }
            let count = try await healthKit.syncMetrics(for: parent, context: modelContext)
            try modelContext.save()
            if count == 0 {
                statusMessage = "Sync finished — no new readings in the last 14 days for \(parent.name). Check Health permissions or add data in the Health app."
            } else {
                statusMessage = "Imported \(count) readings for \(parent.name). Check Home and Charts, or Data Overview above."
            }
            FeedbackService.success()
        } catch {
            statusMessage = error.localizedDescription
            FeedbackService.warning()
        }
    }

    private func loadDemoData() {
        guard !isLoadingDemoData else { return }
        isLoadingDemoData = true
        statusMessage = "Loading demo data…"

        Task { @MainActor in
            await NotificationService.shared.cancelAllScheduledNotifications()
            // Yield so the progress UI can paint before the heavy insert work.
            await Task.yield()
            SampleData.loadYearDemo(into: modelContext)

            let fetched = (try? modelContext.fetch(FetchDescriptor<ParentProfile>(
                sortBy: [SortDescriptor(\.name)]
            ))) ?? []
            parentStore.parentID = fetched.first?.id
            selectedParentForExport = fetched.first?.id
            selectedParentForSync = fetched.first?.id

            if AppSettings.notificationsEnabled {
                await NotificationService.shared.rescheduleAll(parents: fetched)
            }

            isLoadingDemoData = false
            CareSpotlightIndexer.refresh(parents: fetched)
            CareAppShortcuts.updateAppShortcutParameters()
            statusMessage = "Loaded 1 year of demo data. Explore Home, Charts, Labs, and Meds."
            FeedbackService.success()
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
