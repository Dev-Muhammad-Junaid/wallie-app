import Foundation

enum AppSettings {
    private static let healthKitEnabledKey = "healthKitEnabled"
    private static let weeklySummaryEnabledKey = "weeklySummaryEnabled"
    private static let notificationsEnabledKey = "notificationsEnabled"

    static var healthKitEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: healthKitEnabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: healthKitEnabledKey) }
    }

    static var weeklySummaryEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: weeklySummaryEnabledKey) == nil { return true }
            return UserDefaults.standard.bool(forKey: weeklySummaryEnabledKey)
        }
        set { UserDefaults.standard.set(newValue, forKey: weeklySummaryEnabledKey) }
    }

    static var notificationsEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: notificationsEnabledKey) == nil { return true }
            return UserDefaults.standard.bool(forKey: notificationsEnabledKey)
        }
        set { UserDefaults.standard.set(newValue, forKey: notificationsEnabledKey) }
    }

    private static let healthAlertsEnabledKey = "healthAlertsEnabled"

    /// Notify when a new vital or lab value is saved outside normal range.
    static var healthAlertsEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: healthAlertsEnabledKey) == nil { return true }
            return UserDefaults.standard.bool(forKey: healthAlertsEnabledKey)
        }
        set { UserDefaults.standard.set(newValue, forKey: healthAlertsEnabledKey) }
    }

    private static let siriSpotlightIndexingEnabledKey = "siriSpotlightIndexingEnabled"

    /// Donate parent names, medication names, and appointments to Spotlight / Siri AI.
    /// Off by default so health data is not searchable until the caregiver opts in.
    /// App Shortcuts still work when this is off — those are explicit Siri phrases.
    static var siriSpotlightIndexingEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: siriSpotlightIndexingEnabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: siriSpotlightIndexingEnabledKey) }
    }

    private static let hasCompletedOnboardingKey = "hasCompletedOnboarding"

    static var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: hasCompletedOnboardingKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasCompletedOnboardingKey) }
    }

    private static let iCloudSyncEnabledKey = "iCloudSyncEnabled"

    /// Sync parents, meds, labs, and appointments across devices signed into the same iCloud account.
    /// Changing this requires relaunching the app to rebuild the SwiftData container.
    static var iCloudSyncEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: iCloudSyncEnabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: iCloudSyncEnabledKey) }
    }

    private static let useRemoteLabAPIKey = "useRemoteLabAPI"
    private static let labAPIEndpointKey = "labAPIEndpoint"
    private static let labAPIKeyKey = "labAPIKey"

    /// When true and endpoint is set, lab analysis tries your API first (falls back to on-device).
    static var useRemoteLabAPI: Bool {
        get { UserDefaults.standard.bool(forKey: useRemoteLabAPIKey) }
        set { UserDefaults.standard.set(newValue, forKey: useRemoteLabAPIKey) }
    }

    static var labAPIEndpoint: String? {
        get { UserDefaults.standard.string(forKey: labAPIEndpointKey) }
        set { UserDefaults.standard.set(newValue, forKey: labAPIEndpointKey) }
    }

    static var labAPIKey: String {
        get { UserDefaults.standard.string(forKey: labAPIKeyKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: labAPIKeyKey) }
    }
}
