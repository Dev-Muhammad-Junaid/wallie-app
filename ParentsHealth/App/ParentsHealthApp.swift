import SwiftUI
import SwiftData

@main
struct ParentsHealthApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    private static var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("UI_TESTING")
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ParentProfile.self,
            HealthMetric.self,
            Medication.self,
            MedicationLog.self,
            LabReport.self,
            LabResult.self,
            CareProvider.self,
            Appointment.self
        ])
        let inMemory = ProcessInfo.processInfo.arguments.contains("UI_TESTING")

        // CloudKit keeps the same iCloud account in sync across family devices.
        // UI tests and explicit opt-out stay local-only.
        let useCloudKit = !inMemory && AppSettings.iCloudSyncEnabled
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: useCloudKit ? .automatic : .none
        )
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            // Fall back to local store if CloudKit / migration fails (e.g. unsigned builds).
            let local = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory, cloudKitDatabase: .none)
            do {
                return try ModelContainer(for: schema, configurations: local)
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

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
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
