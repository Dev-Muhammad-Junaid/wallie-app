import Foundation

struct ParsedLabResult: Equatable {
    let testKey: LabTestKey
    let testName: String
    let value: Double
    let unit: String
    let referenceRange: String
    let isAbnormal: Bool
}

enum LabReportParser {
    private struct TestPattern {
        let key: LabTestKey
        let unit: String
        let normalRange: ClosedRange<Double>
        let highIsBad: Bool
    }

    private static let patterns: [TestPattern] = [
        TestPattern(key: .glucose, unit: "mg/dL", normalRange: 70...100, highIsBad: true),
        TestPattern(key: .hba1c, unit: "%", normalRange: 4.0...5.7, highIsBad: true),
        TestPattern(key: .cholesterol, unit: "mg/dL", normalRange: 0...200, highIsBad: true),
        TestPattern(key: .ldl, unit: "mg/dL", normalRange: 0...100, highIsBad: true),
        TestPattern(key: .hdl, unit: "mg/dL", normalRange: 40...100, highIsBad: false),
        TestPattern(key: .triglycerides, unit: "mg/dL", normalRange: 0...150, highIsBad: true),
        TestPattern(key: .creatinine, unit: "mg/dL", normalRange: 0.6...1.2, highIsBad: true),
        TestPattern(key: .hemoglobin, unit: "g/dL", normalRange: 12.0...17.5, highIsBad: false),
        TestPattern(key: .wbc, unit: "K/uL", normalRange: 4.5...11.0, highIsBad: true),
        TestPattern(key: .platelet, unit: "K/uL", normalRange: 150...400, highIsBad: true),
        TestPattern(key: .tsh, unit: "mIU/L", normalRange: 0.4...4.0, highIsBad: true),
        TestPattern(key: .vitaminD, unit: "ng/mL", normalRange: 30...100, highIsBad: false),
    ]

    static func parse(text: String) -> [ParsedLabResult] {
        let normalized = text.lowercased()
        var results: [ParsedLabResult] = []
        var foundKeys: Set<LabTestKey> = []

        for pattern in patterns {
            guard !foundKeys.contains(pattern.key) else { continue }
            for name in pattern.key.aliases {
                if let value = extractValue(near: name, in: normalized) {
                    let isAbnormal: Bool
                    if pattern.highIsBad {
                        isAbnormal = value > pattern.normalRange.upperBound || value < pattern.normalRange.lowerBound
                    } else {
                        isAbnormal = value < pattern.normalRange.lowerBound
                    }

                    let rangeText = "\(formatValue(pattern.normalRange.lowerBound))–\(formatValue(pattern.normalRange.upperBound)) \(pattern.unit)"
                    results.append(ParsedLabResult(
                        testKey: pattern.key,
                        testName: pattern.key.title,
                        value: value,
                        unit: pattern.unit,
                        referenceRange: rangeText,
                        isAbnormal: isAbnormal
                    ))
                    foundKeys.insert(pattern.key)
                    break
                }
            }
        }

        return results.sorted { $0.testKey.title < $1.testKey.title }
    }

    static func generateInsights(results: [ParsedLabResult], parentName: String) -> String {
        guard !results.isEmpty else {
            return "No lab values could be extracted. Try a clearer photo or enter values manually."
        }

        let abnormal = results.filter(\.isAbnormal)
        var lines: [String] = []

        if abnormal.isEmpty {
            lines.append("All \(results.count) extracted values for \(parentName) appear within normal ranges.")
        } else {
            lines.append("\(abnormal.count) of \(results.count) values for \(parentName) are outside normal range:")
            for result in abnormal.prefix(5) {
                lines.append("• \(result.testName): \(formatValue(result.value)) \(result.unit) (ref \(result.referenceRange))")
            }
        }

        if abnormal.contains(where: { $0.testKey == .glucose || $0.testKey == .hba1c }) {
            lines.append("Consider discussing blood sugar management with their doctor.")
        }
        if abnormal.contains(where: { [.cholesterol, .ldl, .hdl, .triglycerides].contains($0.testKey) }) {
            lines.append("Lipid panel results may warrant dietary or medication review.")
        }
        if abnormal.contains(where: { $0.testKey == .creatinine }) {
            lines.append("Kidney function markers should be reviewed with a physician.")
        }

        lines.append("This analysis is informational only — not medical advice.")
        return lines.joined(separator: "\n")
    }

    static func extractLabDate(from text: String) -> Date? {
        let patterns = [
            #"(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})"#,
            #"(\d{4})[/-](\d{1,2})[/-](\d{1,2})"#
        ]
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
                  match.numberOfRanges >= 4 else { continue }

            let groups = (1..<match.numberOfRanges).compactMap { index -> String? in
                guard let range = Range(match.range(at: index), in: text) else { return nil }
                return String(text[range])
            }

            if groups.count == 3 {
                if groups[0].count == 4, let y = Int(groups[0]), let m = Int(groups[1]), let d = Int(groups[2]) {
                    return Calendar.current.date(from: DateComponents(year: y, month: m, day: d))
                }
                if let m = Int(groups[0]), let d = Int(groups[1]), var y = Int(groups[2]) {
                    if y < 100 { y += 2000 }
                    return Calendar.current.date(from: DateComponents(year: y, month: m, day: d))
                }
            }
        }
        return nil
    }

    private static func extractValue(near keyword: String, in text: String) -> Double? {
        guard let range = text.range(of: keyword) else { return nil }
        let start = range.upperBound
        let endIndex = text.index(start, offsetBy: 80, limitedBy: text.endIndex) ?? text.endIndex
        let snippet = String(text[start..<endIndex])

        let numberPattern = #"(\d+\.?\d*)"#
        guard let regex = try? NSRegularExpression(pattern: numberPattern) else { return nil }
        let nsRange = NSRange(snippet.startIndex..., in: snippet)
        guard let match = regex.firstMatch(in: snippet, range: nsRange),
              let valueRange = Range(match.range(at: 1), in: snippet) else { return nil }

        return Double(snippet[valueRange])
    }

    private static func formatValue(_ value: Double) -> String {
        if value == value.rounded() { return "\(Int(value))" }
        return String(format: "%.1f", value)
    }
}
