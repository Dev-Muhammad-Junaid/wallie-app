import SwiftUI
import SwiftData

@main
struct ParentsHealthApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ParentProfile.self,
            HealthMetric.self,
            Medication.self,
            MedicationLog.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onAppear {
                    SampleData.seedIfNeeded(context: sharedModelContainer.mainContext)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
