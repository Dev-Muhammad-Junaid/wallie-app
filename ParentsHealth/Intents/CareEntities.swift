import AppIntents
import SwiftData

struct ParentEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Parent")
    static var defaultQuery = ParentEntityQuery()

    var id: UUID
    var name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    init(id: UUID, name: String) {
        self.id = id
        self.name = name
    }

    init(parent: ParentProfile) {
        self.id = parent.id
        self.name = parent.name
    }
}

struct MedicationEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Medication")
    static var defaultQuery = MedicationEntityQuery()

    var id: UUID
    var name: String
    var parentName: String
    var dosage: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: "\(parentName) · \(dosage)"
        )
    }

    init(id: UUID, name: String, parentName: String, dosage: String) {
        self.id = id
        self.name = name
        self.parentName = parentName
        self.dosage = dosage
    }

    init(medication: Medication, parentName: String) {
        self.id = medication.id
        self.name = medication.name
        self.parentName = parentName
        self.dosage = medication.dosage
    }
}

struct AppointmentEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Appointment")
    static var defaultQuery = AppointmentEntityQuery()

    var id: UUID
    var title: String
    var parentName: String
    var scheduledAt: Date

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(title)",
            subtitle: "\(parentName) · \(scheduledAt.formatted(date: .abbreviated, time: .shortened))"
        )
    }

    init(appointment: Appointment, parentName: String) {
        self.id = appointment.id
        self.title = appointment.displayTitle
        self.parentName = parentName
        self.scheduledAt = appointment.scheduledAt
    }
}

struct CareProviderEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Doctor")
    static var defaultQuery = CareProviderEntityQuery()

    var id: UUID
    var name: String
    var parentName: String
    var specialty: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: "\(specialty) · \(parentName)"
        )
    }

    init(provider: CareProvider, parentName: String) {
        self.id = provider.id
        self.name = provider.name
        self.parentName = parentName
        self.specialty = provider.displaySpecialty
    }
}

enum DoseLogAction: String, AppEnum {
    case taken
    case skipped

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Dose action")

    static var caseDisplayRepresentations: [DoseLogAction: DisplayRepresentation] = [
        .taken: "Taken",
        .skipped: "Skipped"
    ]

    var medicationStatus: MedicationStatus {
        switch self {
        case .taken: return .taken
        case .skipped: return .skipped
        }
    }
}

struct ParentEntityQuery: EntityStringQuery {
    func entities(for identifiers: [UUID]) async throws -> [ParentEntity] {
        try await MainActor.run {
            try IntentDependencies.parents()
                .filter { identifiers.contains($0.id) }
                .map(ParentEntity.init(parent:))
        }
    }

    func entities(matching string: String) async throws -> [ParentEntity] {
        try await MainActor.run {
            try IntentDependencies.parents()
                .filter { $0.name.localizedCaseInsensitiveContains(string) }
                .map(ParentEntity.init(parent:))
        }
    }

    func suggestedEntities() async throws -> [ParentEntity] {
        try await MainActor.run {
            try IntentDependencies.parents().map(ParentEntity.init(parent:))
        }
    }
}

struct MedicationEntityQuery: EntityStringQuery {
    func entities(for identifiers: [UUID]) async throws -> [MedicationEntity] {
        try await MainActor.run {
            try allMedicationEntities().filter { identifiers.contains($0.id) }
        }
    }

    func entities(matching string: String) async throws -> [MedicationEntity] {
        try await MainActor.run {
            try allMedicationEntities().filter {
                $0.name.localizedCaseInsensitiveContains(string)
                    || $0.parentName.localizedCaseInsensitiveContains(string)
            }
        }
    }

    func suggestedEntities() async throws -> [MedicationEntity] {
        try await MainActor.run {
            try allMedicationEntities()
        }
    }

    @MainActor
    private func allMedicationEntities() throws -> [MedicationEntity] {
        try IntentDependencies.parents().flatMap { parent in
            parent.medications
                .filter(\.isActive)
                .map { MedicationEntity(medication: $0, parentName: parent.name) }
        }
    }
}

struct AppointmentEntityQuery: EntityStringQuery {
    func entities(for identifiers: [UUID]) async throws -> [AppointmentEntity] {
        try await MainActor.run {
            try upcomingAppointments().filter { identifiers.contains($0.id) }
        }
    }

    func entities(matching string: String) async throws -> [AppointmentEntity] {
        try await MainActor.run {
            try upcomingAppointments().filter {
                $0.title.localizedCaseInsensitiveContains(string)
                    || $0.parentName.localizedCaseInsensitiveContains(string)
            }
        }
    }

    func suggestedEntities() async throws -> [AppointmentEntity] {
        try await MainActor.run {
            try upcomingAppointments()
        }
    }

    @MainActor
    private func upcomingAppointments() throws -> [AppointmentEntity] {
        try IntentDependencies.parents().flatMap { parent in
            parent.appointments
                .filter(\.isUpcoming)
                .map { AppointmentEntity(appointment: $0, parentName: parent.name) }
        }
    }
}

struct CareProviderEntityQuery: EntityStringQuery {
    func entities(for identifiers: [UUID]) async throws -> [CareProviderEntity] {
        try await MainActor.run {
            try allProviders().filter { identifiers.contains($0.id) }
        }
    }

    func entities(matching string: String) async throws -> [CareProviderEntity] {
        try await MainActor.run {
            try allProviders().filter {
                $0.name.localizedCaseInsensitiveContains(string)
                    || $0.parentName.localizedCaseInsensitiveContains(string)
            }
        }
    }

    func suggestedEntities() async throws -> [CareProviderEntity] {
        try await MainActor.run {
            try allProviders()
        }
    }

    @MainActor
    private func allProviders() throws -> [CareProviderEntity] {
        try IntentDependencies.parents().flatMap { parent in
            parent.careProviders.map { CareProviderEntity(provider: $0, parentName: parent.name) }
        }
    }
}

@available(iOS 18.0, *)
extension ParentEntity: IndexedEntity {}

@available(iOS 18.0, *)
extension MedicationEntity: IndexedEntity {}

@available(iOS 18.0, *)
extension AppointmentEntity: IndexedEntity {}

@available(iOS 18.0, *)
extension CareProviderEntity: IndexedEntity {}
