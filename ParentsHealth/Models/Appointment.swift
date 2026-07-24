import Foundation
import SwiftData

/// Scheduled doctor visit for a parent, with optional local reminder.
@Model
final class Appointment {
    var id: UUID
    var title: String
    var scheduledAt: Date
    var location: String
    var notes: String
    /// Minutes before the visit to fire a local notification (0 = none).
    var reminderMinutesBefore: Int
    var createdAt: Date

    var parent: ParentProfile?
    var provider: CareProvider?

    init(
        title: String,
        scheduledAt: Date,
        location: String = "",
        notes: String = "",
        reminderMinutesBefore: Int = 60,
        parent: ParentProfile? = nil,
        provider: CareProvider? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.scheduledAt = scheduledAt
        self.location = location
        self.notes = notes
        self.reminderMinutesBefore = reminderMinutesBefore
        self.createdAt = Date()
        self.parent = parent
        self.provider = provider
    }

    var isUpcoming: Bool {
        scheduledAt >= Date()
    }

    var providerName: String {
        provider?.name ?? "Doctor"
    }

    var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        if let specialty = provider?.specialty, !specialty.isEmpty {
            return "\(specialty) visit"
        }
        return "Doctor appointment"
    }
}
