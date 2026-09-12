import CoreSpotlight
import UniformTypeIdentifiers
import SwiftData
import AppIntents

/// Indexes only names and visit titles — never labs, vitals, or notes.
/// iOS 17 uses Core Spotlight items. iOS 18+ also donates App Entities for Siri AI when available.
enum CareSpotlightIndexer {
    static let domainIdentifier = "com.widgetsflow.parentshealth.care"
    private static let entityIndexName = "ParentsHealthCareEntities"

    static func refresh(parents: [ParentProfile]) {
        Task { await refreshAsync(parents: parents) }
    }

    private static func refreshAsync(parents: [ParentProfile]) async {
        guard AppSettings.siriSpotlightIndexingEnabled else {
            await deleteLegacyItems()
            if #available(iOS 18.0, *) {
                await deleteIndexedEntities()
            }
            return
        }

        if #available(iOS 18.0, *) {
            await indexAppEntities(parents: parents)
        } else {
            await indexLegacyItems(parents: parents)
        }
    }

    private static func indexLegacyItems(parents: [ParentProfile]) async {
        let items = parents.flatMap { parent -> [CSSearchableItem] in
            var batch: [CSSearchableItem] = [searchableItem(for: parent)]
            batch += parent.medications.filter(\.isActive).map { searchableItem(for: $0, parent: parent) }
            batch += parent.appointments.filter(\.isUpcoming).map { searchableItem(for: $0, parent: parent) }
            batch += parent.careProviders.map { searchableItem(for: $0, parent: parent) }
            return batch
        }

        await deleteLegacyItems()
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            CSSearchableIndex.default().indexSearchableItems(items) { _ in
                continuation.resume()
            }
        }
    }

    private static func deleteLegacyItems() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: [domainIdentifier]) { _ in
                continuation.resume()
            }
        }
    }

    private static func searchableItem(for parent: ParentProfile) -> CSSearchableItem {
        let attributes = CSSearchableItemAttributeSet(contentType: UTType.contact)
        attributes.title = parent.name
        attributes.displayName = parent.name
        attributes.contentDescription = "Care profile in ParentsHealth"
        attributes.keywords = ["parent", "ParentsHealth", parent.name]
        return CSSearchableItem(
            uniqueIdentifier: AppDeepLink.spotlightIdentifier(kind: .parent, id: parent.id),
            domainIdentifier: domainIdentifier,
            attributeSet: attributes
        )
    }

    private static func searchableItem(for medication: Medication, parent: ParentProfile) -> CSSearchableItem {
        let attributes = CSSearchableItemAttributeSet(contentType: UTType.content)
        attributes.title = medication.name
        attributes.contentDescription = "Medication for \(parent.name)"
        attributes.keywords = [medication.name, parent.name, "medication"]
        return CSSearchableItem(
            uniqueIdentifier: AppDeepLink.spotlightIdentifier(kind: .medication, id: medication.id),
            domainIdentifier: domainIdentifier,
            attributeSet: attributes
        )
    }

    private static func searchableItem(for appointment: Appointment, parent: ParentProfile) -> CSSearchableItem {
        let attributes = CSSearchableItemAttributeSet(contentType: UTType.calendarEvent)
        attributes.title = appointment.displayTitle
        attributes.contentDescription = "Visit for \(parent.name)"
        attributes.startDate = appointment.scheduledAt
        attributes.keywords = [appointment.displayTitle, parent.name]
        return CSSearchableItem(
            uniqueIdentifier: AppDeepLink.spotlightIdentifier(kind: .appointment, id: appointment.id),
            domainIdentifier: domainIdentifier,
            attributeSet: attributes
        )
    }

    private static func searchableItem(for provider: CareProvider, parent: ParentProfile) -> CSSearchableItem {
        let attributes = CSSearchableItemAttributeSet(contentType: UTType.contact)
        attributes.title = provider.name
        attributes.contentDescription = "\(provider.displaySpecialty) for \(parent.name)"
        attributes.keywords = [provider.name, parent.name]
        return CSSearchableItem(
            uniqueIdentifier: AppDeepLink.spotlightIdentifier(kind: .provider, id: provider.id),
            domainIdentifier: domainIdentifier,
            attributeSet: attributes
        )
    }

    @available(iOS 18.0, *)
    private static func indexAppEntities(parents: [ParentProfile]) async {
        let parentEntities = parents.map(ParentEntity.init(parent:))
        let medicationEntities = parents.flatMap { parent in
            parent.medications.filter(\.isActive).map { MedicationEntity(medication: $0, parentName: parent.name) }
        }
        let appointmentEntities = parents.flatMap { parent in
            parent.appointments.filter(\.isUpcoming).map { AppointmentEntity(appointment: $0, parentName: parent.name) }
        }
        let providerEntities = parents.flatMap { parent in
            parent.careProviders.map { CareProviderEntity(provider: $0, parentName: parent.name) }
        }

        do {
            let index = CSSearchableIndex(name: entityIndexName)
            try await index.indexAppEntities(parentEntities)
            try await index.indexAppEntities(medicationEntities)
            try await index.indexAppEntities(appointmentEntities)
            try await index.indexAppEntities(providerEntities)
        } catch {
            await indexLegacyItems(parents: parents)
        }
    }

    @available(iOS 18.0, *)
    private static func deleteIndexedEntities() async {
        do {
            try await CSSearchableIndex(name: entityIndexName).deleteAllSearchableItems()
        } catch {
            await deleteLegacyItems()
        }
    }
}
