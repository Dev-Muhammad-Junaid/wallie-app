import SwiftUI
import SwiftData
import AppIntents

@main
struct ParentsHealthApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    private static var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("UI_TESTING")
    }

    var sharedModelContainer: ModelContainer

    init() {
        let container = Persistence.makeContainer()
        sharedModelContainer = container
        IntentDependencies.register(container: container)
        CareAppShortcuts.updateAppShortcutParameters()
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(SelectedParentStore())
                .environmentObject(AppNavigationStore())
                .onAppear {
                    if !Self.isUITesting {
                        SampleData.seedIfNeeded(context: sharedModelContainer.mainContext)
                    } else {
                        SampleData.seed(into: sharedModelContainer.mainContext)
                    }
                    refreshSiriIndex()
                }
        }
        .modelContainer(sharedModelContainer)
    }

    private func refreshSiriIndex() {
        let parents = (try? sharedModelContainer.mainContext.fetch(FetchDescriptor<ParentProfile>())) ?? []
        CareSpotlightIndexer.refresh(parents: parents)
        CareAppShortcuts.updateAppShortcutParameters()
    }
}

enum Persistence {
    static let schema = Schema([
        ParentProfile.self,
        HealthMetric.self,
        Medication.self,
        MedicationLog.self,
        LabReport.self,
        LabResult.self,
        CareProvider.self,
        Appointment.self
    ])

    static func makeContainer() -> ModelContainer {
        let inMemory = ProcessInfo.processInfo.arguments.contains("UI_TESTING")
        // CloudKit is off unless the user explicitly enabled it. Personal-team
        // installs have no iCloud entitlement; opening .automatic traps in SwiftData.
        let cloudKit = !inMemory && AppSettings.iCloudSyncEnabled
        return openContainer(inMemory: inMemory, cloudKit: cloudKit, allowReset: !inMemory)
    }

    private static func openContainer(inMemory: Bool, cloudKit: Bool, allowReset: Bool) -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: cloudKit ? .automatic : .none
        )
        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            if cloudKit {
                return openContainer(inMemory: inMemory, cloudKit: false, allowReset: allowReset)
            }
            guard allowReset else {
                fatalError("Could not create ModelContainer: \(error)")
            }
            wipeStore(at: configuration.url)
            do {
                return try ModelContainer(for: schema, configurations: configuration)
            } catch {
                fatalError("Could not create ModelContainer after reset: \(error)")
            }
        }
    }

    private static func wipeStore(at url: URL) {
        let directory = url.deletingLastPathComponent()
        let extras = [
            url,
            URL(fileURLWithPath: url.path + "-wal"),
            URL(fileURLWithPath: url.path + "-shm")
        ]
        for file in extras {
            try? FileManager.default.removeItem(at: file)
        }
        if let files = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) {
            for file in files where file.lastPathComponent.contains("default.store") || file.pathExtension == "store" {
                try? FileManager.default.removeItem(at: file)
            }
        }
    }
}
