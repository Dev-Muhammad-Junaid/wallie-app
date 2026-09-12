import Foundation

/// Custom URL scheme used by Shortcuts, Spotlight, and Siri on every supported iOS version.
enum AppDeepLink {
    static let scheme = "parentshealth"

    enum Destination: Equatable {
        case parent(UUID)
        case medications(parentID: UUID?)
        case labs
        case charts
        case care
        case appointment(UUID)
        case alerts

        var navigationType: String {
            switch self {
            case .parent: return "open_parent"
            case .medications: return "medication"
            case .labs: return "open_labs"
            case .charts: return "open_charts"
            case .care, .appointment: return "appointment"
            case .alerts: return "health_alert"
            }
        }
    }

    static func url(for destination: Destination) -> URL {
        switch destination {
        case let .parent(id):
            return URL(string: "\(scheme)://parent/\(id.uuidString)")!
        case let .medications(parentID):
            if let parentID {
                return URL(string: "\(scheme)://meds/\(parentID.uuidString)")!
            }
            return URL(string: "\(scheme)://meds")!
        case .labs:
            return URL(string: "\(scheme)://labs")!
        case .charts:
            return URL(string: "\(scheme)://charts")!
        case .care:
            return URL(string: "\(scheme)://care")!
        case let .appointment(id):
            return URL(string: "\(scheme)://appointment/\(id.uuidString)")!
        case .alerts:
            return URL(string: "\(scheme)://alerts")!
        }
    }

    static func parse(_ url: URL) -> Destination? {
        guard url.scheme?.lowercased() == scheme else { return nil }
        let host = url.host?.lowercased() ?? ""
        let pathID = uuid(from: url.pathComponents)
        switch host {
        case "parent":
            guard let pathID else { return nil }
            return .parent(pathID)
        case "meds", "medications":
            return .medications(parentID: pathID)
        case "labs":
            return .labs
        case "charts":
            return .charts
        case "care":
            return .care
        case "appointment":
            guard let pathID else { return .care }
            return .appointment(pathID)
        case "alerts":
            return .alerts
        default:
            return nil
        }
    }

    /// Spotlight identifiers used on iOS 17 (Core Spotlight) and as a fallback on later versions.
    static func spotlightIdentifier(kind: SpotlightKind, id: UUID) -> String {
        "\(kind.rawValue):\(id.uuidString)"
    }

    static func destination(fromSpotlightIdentifier identifier: String) -> Destination? {
        let parts = identifier.split(separator: ":", maxSplits: 1).map(String.init)
        guard parts.count == 2, let id = UUID(uuidString: parts[1]), let kind = SpotlightKind(rawValue: parts[0]) else {
            return nil
        }
        switch kind {
        case .parent:
            return .parent(id)
        case .medication:
            return .medications(parentID: nil)
        case .appointment:
            return .appointment(id)
        case .provider:
            return .care
        }
    }

    static func post(_ destination: Destination) {
        var userInfo: [String: String] = ["type": destination.navigationType]
        switch destination {
        case let .parent(id):
            userInfo["parentID"] = id.uuidString
        case let .medications(parentID):
            if let parentID {
                userInfo["parentID"] = parentID.uuidString
            }
        case let .appointment(id):
            userInfo["appointmentID"] = id.uuidString
        case .labs, .charts, .care, .alerts:
            break
        }
        NotificationCenter.default.post(
            name: .appNavigationRequested,
            object: nil,
            userInfo: userInfo
        )
    }

    private static func uuid(from pathComponents: [String]) -> UUID? {
        pathComponents
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "/")) }
            .compactMap(UUID.init(uuidString:))
            .first
    }
}

enum SpotlightKind: String {
    case parent
    case medication
    case appointment
    case provider
}
