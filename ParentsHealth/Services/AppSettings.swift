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
}
