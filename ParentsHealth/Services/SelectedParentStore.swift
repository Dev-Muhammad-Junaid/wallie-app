import SwiftUI

@MainActor
final class SelectedParentStore: ObservableObject {
    @Published var parentID: UUID? {
        didSet { persistParentID() }
    }

    private static let storageKey = "selectedParentID"

    init() {
        if let raw = UserDefaults.standard.string(forKey: Self.storageKey),
           let id = UUID(uuidString: raw) {
            parentID = id
        }
    }

    func parent(from parents: [ParentProfile]) -> ParentProfile? {
        if let id = parentID {
            return parents.first { $0.id == id }
        }
        return parents.first
    }

    func ensureSelection(from parents: [ParentProfile]) {
        if parentID == nil || !parents.contains(where: { $0.id == parentID }) {
            parentID = parents.first?.id
        }
    }

    private func persistParentID() {
        if let parentID {
            UserDefaults.standard.set(parentID.uuidString, forKey: Self.storageKey)
        } else {
            UserDefaults.standard.removeObject(forKey: Self.storageKey)
        }
    }
}
