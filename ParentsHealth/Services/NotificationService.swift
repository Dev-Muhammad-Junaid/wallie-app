import Foundation
import UserNotifications

@MainActor
final class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published private(set) var isAuthorized = false

    private let center = UNUserNotificationCenter.current()

    private init() {}

    func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            return granted
        } catch {
            isAuthorized = false
            return false
        }
    }

    func scheduleMedicationReminders(for medication: Medication) async {
        guard isAuthorized, medication.isActive else { return }

        await cancelMedicationReminders(for: medication)

        let parentName = medication.parent?.name ?? "your parent"
        for hour in medication.reminderHours {
            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = 0

            let content = UNMutableNotificationContent()
            content.title = "Medication Reminder"
            content.body = "Time for \(medication.name) (\(medication.dosage)) — \(parentName)"
            content.sound = .default
            content.categoryIdentifier = "MEDICATION_REMINDER"
            content.userInfo = [
                "medicationId": medication.id.uuidString,
                "type": "medication"
            ]

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let identifier = Self.medicationIdentifier(medicationId: medication.id, hour: hour)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            try? await center.add(request)
        }
    }

    func cancelMedicationReminders(for medication: Medication) async {
        let identifiers = medication.reminderHours.map {
            Self.medicationIdentifier(medicationId: medication.id, hour: $0)
        }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func scheduleWeeklySummary(for parents: [ParentProfile]) async {
        guard isAuthorized else { return }

        let identifier = "weekly-summary"
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        var dateComponents = DateComponents()
        dateComponents.weekday = 1 // Sunday
        dateComponents.hour = 9
        dateComponents.minute = 0

        let content = UNMutableNotificationContent()
        content.title = "Weekly Health Summary"
        content.body = weeklySummaryBody(parents: parents)
        content.sound = .default
        content.userInfo = ["type": "weekly_summary"]

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try? await center.add(request)
    }

    func rescheduleAll(parents: [ParentProfile]) async {
        guard isAuthorized else { return }
        let medications = parents.flatMap(\.medications).filter(\.isActive)
        for medication in medications {
            await scheduleMedicationReminders(for: medication)
        }
        if AppSettings.weeklySummaryEnabled {
            await scheduleWeeklySummary(for: parents)
        }
    }

    func notifyHealthAlert(_ alert: HealthAlert) async {
        guard isAuthorized, AppSettings.notificationsEnabled, AppSettings.healthAlertsEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Health Alert · \(alert.parentName)"
        content.body = "\(alert.title): \(alert.valueText) — \(alert.boundary.label). \(alert.careHint)"
        content.sound = .default
        content.categoryIdentifier = "HEALTH_ALERT"
        content.userInfo = [
            "type": "health_alert",
            "parentId": alert.parentID.uuidString,
            "alertId": alert.id
        ]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let identifier = "health-alert-\(alert.id)-\(UUID().uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try? await center.add(request)
    }

    func notifyHealthAlerts(_ alerts: [HealthAlert]) async {
        for alert in alerts {
            await notifyHealthAlert(alert)
        }
    }

    static func medicationIdentifier(medicationId: UUID, hour: Int) -> String {
        "med-\(medicationId.uuidString)-\(hour)"
    }

    private func weeklySummaryBody(parents: [ParentProfile]) -> String {
        guard !parents.isEmpty else {
            return "Add a parent profile to start tracking health."
        }
        let summaries = parents.map { parent in
            "\(parent.name): health score \(parent.healthScore())"
        }
        return summaries.joined(separator: " · ")
    }
}
