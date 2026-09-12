import AppIntents
import SwiftData

enum IntentDependencies {
    private(set) static var container: ModelContainer?

    static func register(container: ModelContainer) {
        self.container = container
        AppDependencyManager.shared.add(key: "ModelContainer") { container }
    }

    static func requireContainer() throws -> ModelContainer {
        guard let container else {
            throw CareIntentError.storeUnavailable
        }
        return container
    }

    @MainActor
    static func context() throws -> ModelContext {
        try requireContainer().mainContext
    }

    @MainActor
    static func parents() throws -> [ParentProfile] {
        try context().fetch(FetchDescriptor<ParentProfile>(sortBy: [SortDescriptor(\.name)]))
    }

    @MainActor
    static func parent(id: UUID) throws -> ParentProfile? {
        try parents().first { $0.id == id }
    }

    @MainActor
    static func medication(id: UUID) throws -> Medication? {
        try parents().flatMap(\.medications).first { $0.id == id }
    }

    @MainActor
    static func provider(id: UUID) throws -> CareProvider? {
        try parents().flatMap(\.careProviders).first { $0.id == id }
    }
}

enum CareIntentError: Error, CustomLocalizedStringResourceConvertible {
    case storeUnavailable
    case notFound
    case noParents

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .storeUnavailable:
            return "Open ParentsHealth once, then try Siri again."
        case .notFound:
            return "That item wasn’t found in ParentsHealth."
        case .noParents:
            return "Add a parent profile in ParentsHealth first."
        }
    }
}
