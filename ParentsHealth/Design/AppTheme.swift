import SwiftUI

enum AppTheme {
    static let deepTeal = Color(red: 0.05, green: 0.35, blue: 0.38)
    static let warmCoral = Color(red: 0.95, green: 0.45, blue: 0.38)
    static let softMint = Color(red: 0.55, green: 0.85, blue: 0.78)
    static let midnight = Color(red: 0.06, green: 0.09, blue: 0.14)
    static let cardInk = Color.white.opacity(0.92)

    static let metricBP = Color(red: 0.92, green: 0.35, blue: 0.38)
    static let metricWeight = Color(red: 0.35, green: 0.65, blue: 0.95)
    static let metricHeart = Color(red: 0.95, green: 0.45, blue: 0.55)
    static let metricGlucose = Color(red: 0.55, green: 0.75, blue: 0.35)

    static func metricColor(for type: MetricType) -> Color {
        switch type {
        case .bloodPressure: return metricBP
        case .weight: return metricWeight
        case .heartRate: return metricHeart
        case .bloodGlucose: return metricGlucose
        }
    }

    static let sectionSpacing: CGFloat = 20
    static let cardRadius: CGFloat = 22
    static let chipRadius: CGFloat = 14
}

extension Font {
    static let displayTitle = Font.system(.largeTitle, design: .rounded).weight(.bold)
    static let sectionHeadline = Font.system(.title3, design: .rounded).weight(.semibold)
    static let metricValue = Font.system(.title2, design: .rounded).weight(.bold)
    static let captionMuted = Font.system(.caption, design: .rounded).weight(.medium)
}
