import SwiftUI

@MainActor
final class SelectedParentStore: ObservableObject {
    @Published var parentID: UUID?

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
}
