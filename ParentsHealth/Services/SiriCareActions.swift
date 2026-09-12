import Foundation
import SwiftData

/// Shared care actions used by Siri/Shortcuts and the in-app UI.
/// Keep this free of App Intents so iOS 17 unit tests and the Meds screen stay in sync.
enum SiriCareActions {
    struct PendingDose: Equatable {
        let parentID: UUID
        let parentName: String
        let medicationID: UUID
        let medicationName: String
        let dosage: String
        let hour: Int?
    }

    struct AppointmentSummary: Equatable {
        let id: UUID
        let parentID: UUID
        let parentName: String
        let title: String
        let scheduledAt: Date
        let location: String
        let providerName: String
    }

    enum DoseOutcome: Equatable {
        case logged(medicationName: String, parentName: String, status: MedicationStatus, hour: Int)
        case notDue(medicationName: String, schedule: String)
        case inactive(medicationName: String)
        case notFound
    }

    enum VitalOutcome: Equatable {
        case saved(display: String, parentName: String, inRange: Bool)
        case invalid(String)
        case parentNotFound
    }

    static func logDose(
        medication: Medication,
        status: MedicationStatus,
        hour: Int?,
        now: Date = Date(),
        calendar: Calendar = .current,
        context: ModelContext
    ) -> DoseOutcome {
        guard medication.isActive else {
            return .inactive(medicationName: medication.name)
        }
        guard medication.allowsDoseLoggingToday else {
            return .notDue(medicationName: medication.name, schedule: medication.scheduleSummary)
        }

        let resolvedHour = hour
            ?? medication.pendingReminderHoursToday.first
            ?? calendar.component(.hour, from: now)
        let parentName = medication.parent?.name ?? "this parent"
        let day = calendar.startOfDay(for: now)
        let stamped = calendar.date(
            bySettingHour: resolvedHour,
            minute: min(calendar.component(.minute, from: now), 59),
            second: 0,
            of: day
        ) ?? now

        if let existing = medication.todayLog(forHour: resolvedHour) {
            existing.status = status
            existing.takenAt = stamped
        } else {
            let log = MedicationLog(status: status, takenAt: stamped, medication: medication)
            context.insert(log)
        }

        return .logged(
            medicationName: medication.name,
            parentName: parentName,
            status: status,
            hour: resolvedHour
        )
    }

    static func pendingDoses(
        from parents: [ParentProfile],
        parentID: UUID? = nil
    ) -> [PendingDose] {
        let scoped = parents.filter { parentID == nil || $0.id == parentID }
        return scoped.flatMap { parent in
            parent.medications
                .filter(\.isActive)
                .flatMap { medication -> [PendingDose] in
                    if medication.frequencyKind == .asNeeded {
                        return []
                    }
                    let hours = medication.pendingReminderHoursToday
                    if hours.isEmpty { return [] }
                    return hours.map { hour in
                        PendingDose(
                            parentID: parent.id,
                            parentName: parent.name,
                            medicationID: medication.id,
                            medicationName: medication.name,
                            dosage: medication.dosage,
                            hour: hour
                        )
                    }
                }
        }
        .sorted {
            ($0.parentName, $0.hour ?? 0, $0.medicationName)
                < ($1.parentName, $1.hour ?? 0, $1.medicationName)
        }
    }

    static func pendingSummary(from parents: [ParentProfile], parentID: UUID? = nil) -> String {
        let doses = pendingDoses(from: parents, parentID: parentID)
        let scopeName = parents.first(where: { $0.id == parentID })?.name
        if doses.isEmpty {
            if let scopeName {
                return "No medication doses are waiting for \(scopeName) today."
            }
            return "No medication doses are waiting today."
        }

        let listed = doses.prefix(6).map { dose in
            if let hour = dose.hour {
                return "\(dose.medicationName) for \(dose.parentName) at \(String(format: "%02d:00", hour))"
            }
            return "\(dose.medicationName) for \(dose.parentName)"
        }
        var summary = listed.joined(separator: ". ")
        if doses.count > listed.count {
            summary += ". And \(doses.count - listed.count) more."
        }
        return summary
    }

    static func nextAppointment(
        from parents: [ParentProfile],
        parentID: UUID? = nil,
        now: Date = Date()
    ) -> AppointmentSummary? {
        let scoped = parents.filter { parentID == nil || $0.id == parentID }
        return scoped
            .flatMap(\.appointments)
            .filter { $0.scheduledAt >= now }
            .sorted { $0.scheduledAt < $1.scheduledAt }
            .first
            .map { appointment in
                AppointmentSummary(
                    id: appointment.id,
                    parentID: appointment.parent?.id ?? parentID ?? UUID(),
                    parentName: appointment.parent?.name ?? "this parent",
                    title: appointment.displayTitle,
                    scheduledAt: appointment.scheduledAt,
                    location: appointment.location,
                    providerName: appointment.providerName
                )
            }
    }

    static func appointmentSummaryText(_ appointment: AppointmentSummary?) -> String {
        guard let appointment else {
            return "There are no upcoming doctor appointments."
        }
        let when = appointment.scheduledAt.formatted(date: .abbreviated, time: .shortened)
        var text = "\(appointment.parentName)’s next visit is \(appointment.title) on \(when)"
        if !appointment.providerName.isEmpty {
            text += " with \(appointment.providerName)"
        }
        if !appointment.location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            text += " at \(appointment.location)"
        }
        text += "."
        return text
    }

    static func spokenDose(_ outcome: DoseOutcome) -> String {
        switch outcome {
        case let .logged(medicationName, parentName, status, hour):
            let action = status == .taken ? "taken" : "skipped"
            return "Logged \(medicationName) as \(action) for \(parentName) at \(String(format: "%02d:00", hour))."
        case let .notDue(medicationName, schedule):
            return "\(medicationName) isn’t due today. Schedule: \(schedule)."
        case let .inactive(medicationName):
            return "\(medicationName) is inactive, so it wasn’t logged."
        case .notFound:
            return "That medication wasn’t found."
        }
    }

    static func logBloodPressure(
        parent: ParentProfile,
        systolic: Double,
        diastolic: Double,
        context: ModelContext
    ) -> VitalOutcome {
        guard systolic > 0, diastolic > 0, systolic > diastolic else {
            return .invalid("Blood pressure needs a systolic value higher than diastolic.")
        }
        guard (50...250).contains(systolic), (30...150).contains(diastolic) else {
            return .invalid("Those blood pressure numbers look out of range. Check them in the app.")
        }

        let metric = HealthMetric(
            type: .bloodPressure,
            value: systolic,
            secondaryValue: diastolic,
            notes: "Logged with Siri",
            parent: parent
        )
        context.insert(metric)
        return .saved(
            display: metric.displayValue,
            parentName: parent.name,
            inRange: metric.isInNormalRange
        )
    }

    static func spokenVital(_ outcome: VitalOutcome) -> String {
        switch outcome {
        case let .saved(display, parentName, inRange):
            if inRange {
                return "Saved blood pressure \(display) for \(parentName)."
            }
            return "Saved blood pressure \(display) for \(parentName). It’s outside the usual range — check Alerts in the app."
        case let .invalid(message):
            return message
        case .parentNotFound:
            return "Add a parent profile in ParentsHealth first."
        }
    }
}
