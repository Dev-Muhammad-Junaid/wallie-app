import Foundation
import SwiftData

/// Doctor or clinic contact saved for a parent so caregivers can call quickly.
@Model
final class CareProvider {
    var id: UUID
    var name: String
    var specialty: String
    var phone: String
    var email: String
    var clinic: String
    var notes: String
    var createdAt: Date

    var parent: ParentProfile?

    @Relationship(deleteRule: .nullify, inverse: \Appointment.provider)
    var appointments: [Appointment]

    init(
        name: String,
        specialty: String = "",
        phone: String = "",
        email: String = "",
        clinic: String = "",
        notes: String = "",
        parent: ParentProfile? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.specialty = specialty
        self.phone = phone
        self.email = email
        self.clinic = clinic
        self.notes = notes
        self.createdAt = Date()
        self.parent = parent
        self.appointments = []
    }

    var phoneURL: URL? {
        let digits = phone.filter(\.isNumber)
        guard !digits.isEmpty else { return nil }
        return URL(string: "tel://\(digits)")
    }

    var displaySpecialty: String {
        specialty.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Care provider"
            : specialty
    }
}
