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
            LabResult.self
        ])
        let inMemory = ProcessInfo.processInfo.arguments.contains("UI_TESTING")
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
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
