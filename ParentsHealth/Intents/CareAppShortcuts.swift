import AppIntents

struct CareAppShortcuts: AppShortcutsProvider {
    static var shortcutTileColor: ShortcutTileColor { .teal }

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogMedicationDoseIntent(),
            phrases: [
                "Log a dose in \(.applicationName)",
                "Log medication in \(.applicationName)",
                "Mark a dose taken in \(.applicationName)"
            ],
            shortTitle: "Log dose",
            systemImageName: "pills.fill"
        )
        AppShortcut(
            intent: GetPendingMedicationsIntent(),
            phrases: [
                "What’s due today in \(.applicationName)",
                "Pending medications in \(.applicationName)",
                "Did they take their meds in \(.applicationName)"
            ],
            shortTitle: "What’s due",
            systemImageName: "checklist"
        )
        AppShortcut(
            intent: GetNextAppointmentIntent(),
            phrases: [
                "Next appointment in \(.applicationName)",
                "When is the next doctor visit in \(.applicationName)"
            ],
            shortTitle: "Next visit",
            systemImageName: "calendar"
        )
        AppShortcut(
            intent: OpenMedicationsIntent(),
            phrases: [
                "Open medications in \(.applicationName)",
                "Show meds in \(.applicationName)"
            ],
            shortTitle: "Open Meds",
            systemImageName: "pills"
        )
        AppShortcut(
            intent: LogBloodPressureIntent(),
            phrases: [
                "Log blood pressure in \(.applicationName)",
                "Record blood pressure in \(.applicationName)"
            ],
            shortTitle: "Log BP",
            systemImageName: "heart.fill"
        )
        AppShortcut(
            intent: CallCareProviderIntent(),
            phrases: [
                "Call the doctor in \(.applicationName)",
                "Call a care provider in \(.applicationName)"
            ],
            shortTitle: "Call doctor",
            systemImageName: "phone.fill"
        )
        AppShortcut(
            intent: OpenParentIntent(),
            phrases: [
                "Open a parent in \(.applicationName)",
                "Show parent profile in \(.applicationName)"
            ],
            shortTitle: "Open parent",
            systemImageName: "person.fill"
        )
        AppShortcut(
            intent: OpenCareNetworkIntent(),
            phrases: [
                "Open care network in \(.applicationName)",
                "Show doctors in \(.applicationName)"
            ],
            shortTitle: "Care Network",
            systemImageName: "stethoscope"
        )
    }
}
