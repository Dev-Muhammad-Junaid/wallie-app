import AppIntents
import SwiftData
import UIKit

struct LogMedicationDoseIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Medication Dose"
    static var description = IntentDescription("Marks a parent’s medication as taken or skipped. Works with Siri and Shortcuts on iOS 17 and later.")
    static var openAppWhenRun = false

    @Parameter(title: "Medication", requestValueDialog: "Which medication?")
    var medication: MedicationEntity

    @Parameter(title: "Action")
    var action: DoseLogAction

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$medication) as \(\.$action)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let stored = try IntentDependencies.medication(id: medication.id) else {
            throw CareIntentError.notFound
        }
        let context = try IntentDependencies.context()
        let outcome = SiriCareActions.logDose(
            medication: stored,
            status: action.medicationStatus,
            hour: nil,
            context: context
        )
        try context.save()
        return .result(dialog: IntentDialog(stringLiteral: SiriCareActions.spokenDose(outcome)))
    }
}

struct GetPendingMedicationsIntent: AppIntent {
    static var title: LocalizedStringResource = "What’s Due Today"
    static var description = IntentDescription("Reads which medication doses still need logging today. Does not give medical advice.")
    static var openAppWhenRun = false

    @Parameter(title: "Parent")
    var parent: ParentEntity?

    static var parameterSummary: some ParameterSummary {
        When(\.$parent, .hasAnyValue) {
            Summary("What’s due today for \(\.$parent)")
        } otherwise: {
            Summary("What’s due today")
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<String> {
        let parents = try IntentDependencies.parents()
        let summary = SiriCareActions.pendingSummary(from: parents, parentID: parent?.id)
        return .result(value: summary, dialog: IntentDialog(stringLiteral: summary))
    }
}

struct GetNextAppointmentIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Doctor Appointment"
    static var description = IntentDescription("Tells you the next saved doctor visit for a parent.")
    static var openAppWhenRun = false

    @Parameter(title: "Parent")
    var parent: ParentEntity?

    static var parameterSummary: some ParameterSummary {
        When(\.$parent, .hasAnyValue) {
            Summary("Next appointment for \(\.$parent)")
        } otherwise: {
            Summary("Next doctor appointment")
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<String> {
        let parents = try IntentDependencies.parents()
        let next = SiriCareActions.nextAppointment(from: parents, parentID: parent?.id)
        let summary = SiriCareActions.appointmentSummaryText(next)
        return .result(value: summary, dialog: IntentDialog(stringLiteral: summary))
    }
}

struct OpenParentIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Parent"
    static var description = IntentDescription("Opens a parent’s profile in ParentsHealth.")
    static var openAppWhenRun = true

    @Parameter(title: "Parent", requestValueDialog: "Which parent?")
    var parent: ParentEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Open \(\.$parent)")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        AppDeepLink.post(.parent(parent.id))
        return .result()
    }
}

struct OpenMedicationsIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Medications"
    static var description = IntentDescription("Opens the Meds tab in ParentsHealth.")
    static var openAppWhenRun = true

    @Parameter(title: "Parent")
    var parent: ParentEntity?

    static var parameterSummary: some ParameterSummary {
        When(\.$parent, .hasAnyValue) {
            Summary("Open medications for \(\.$parent)")
        } otherwise: {
            Summary("Open medications")
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        AppDeepLink.post(.medications(parentID: parent?.id))
        return .result()
    }
}

struct OpenLabsIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Labs"
    static var description = IntentDescription("Opens lab reports in ParentsHealth.")
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        AppDeepLink.post(.labs)
        return .result()
    }
}

struct OpenCareNetworkIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Care Network"
    static var description = IntentDescription("Opens doctors and appointments in ParentsHealth.")
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        AppDeepLink.post(.care)
        return .result()
    }
}

struct CallCareProviderIntent: AppIntent {
    static var title: LocalizedStringResource = "Call Doctor"
    static var description = IntentDescription("Places a phone call to a saved care provider.")
    static var openAppWhenRun = true

    @Parameter(title: "Doctor", requestValueDialog: "Which doctor should I call?")
    var provider: CareProviderEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Call \(\.$provider)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let stored = try IntentDependencies.provider(id: provider.id) else {
            throw CareIntentError.notFound
        }
        guard let url = stored.phoneURL else {
            AppDeepLink.post(.care)
            return .result(dialog: "No phone number is saved for \(stored.name). I opened Care Network so you can add one.")
        }
        await UIApplication.shared.open(url)
        return .result(dialog: "Calling \(stored.name).")
    }
}

struct LogBloodPressureIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Blood Pressure"
    static var description = IntentDescription("Saves a blood pressure reading for a parent. Does not interpret the result as medical advice.")
    static var openAppWhenRun = false

    @Parameter(title: "Parent", requestValueDialog: "Whose blood pressure?")
    var parent: ParentEntity

    @Parameter(title: "Systolic")
    var systolic: Int

    @Parameter(title: "Diastolic")
    var diastolic: Int

    static var parameterSummary: some ParameterSummary {
        Summary("Log blood pressure \(\.$systolic)/\(\.$diastolic) for \(\.$parent)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let stored = try IntentDependencies.parent(id: parent.id) else {
            throw CareIntentError.noParents
        }
        let context = try IntentDependencies.context()
        let outcome = SiriCareActions.logBloodPressure(
            parent: stored,
            systolic: Double(systolic),
            diastolic: Double(diastolic),
            context: context
        )
        if case let .saved(_, _, inRange) = outcome, !inRange,
           let metric = stored.metrics.max(by: { $0.recordedAt < $1.recordedAt }),
           let alert = HealthAlertService.alertIfNeeded(for: metric, parent: stored) {
            await NotificationService.shared.notifyHealthAlert(alert)
        }
        try context.save()
        return .result(dialog: IntentDialog(stringLiteral: SiriCareActions.spokenVital(outcome)))
    }
}

@available(iOS 18.0, *)
struct OpenIndexedParentIntent: OpenIntent {
    static var title: LocalizedStringResource = "Open Parent from Search"
    static var isDiscoverable = false

    @Parameter(title: "Parent")
    var target: ParentEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        AppDeepLink.post(.parent(target.id))
        return .result()
    }
}

@available(iOS 18.0, *)
struct OpenIndexedMedicationIntent: OpenIntent {
    static var title: LocalizedStringResource = "Open Medication from Search"
    static var isDiscoverable = false

    @Parameter(title: "Medication")
    var target: MedicationEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        AppDeepLink.post(.medications(parentID: nil))
        return .result()
    }
}

@available(iOS 18.0, *)
struct OpenIndexedAppointmentIntent: OpenIntent {
    static var title: LocalizedStringResource = "Open Appointment from Search"
    static var isDiscoverable = false

    @Parameter(title: "Appointment")
    var target: AppointmentEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        AppDeepLink.post(.appointment(target.id))
        return .result()
    }
}

@available(iOS 18.0, *)
struct OpenIndexedProviderIntent: OpenIntent {
    static var title: LocalizedStringResource = "Open Doctor from Search"
    static var isDiscoverable = false

    @Parameter(title: "Doctor")
    var target: CareProviderEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        AppDeepLink.post(.care)
        return .result()
    }
}
