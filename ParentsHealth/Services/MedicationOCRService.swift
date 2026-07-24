import Foundation
import UIKit
import Vision

/// Extracts medication name and dosage from a bottle/label photo using on-device OCR.
enum MedicationOCRService {
    struct ParsedMedication {
        var name: String
        var dosage: String
        var rawText: String
    }

    static func recognizeText(from image: UIImage) async throws -> String {
        try await LabReportOCRService.recognizeText(from: image)
    }

    static func parse(from image: UIImage) async throws -> ParsedMedication {
        let text = try await recognizeText(from: image)
        return parse(text: text)
    }

    static func parse(text: String) -> ParsedMedication {
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let dosage = extractDosage(from: lines) ?? ""
        let name = extractName(from: lines, excludingDosage: dosage) ?? lines.first ?? ""

        return ParsedMedication(name: name, dosage: dosage, rawText: text)
    }

    private static func extractDosage(from lines: [String]) -> String? {
        let pattern = #"(?i)\b(\d+(?:\.\d+)?\s?(?:mg|mcg|µg|g|ml|iu|units?))\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }

        for line in lines {
            let range = NSRange(line.startIndex..<line.endIndex, in: line)
            if let match = regex.firstMatch(in: line, range: range),
               let swiftRange = Range(match.range, in: line) {
                return String(line[swiftRange])
                    .replacingOccurrences(of: #"\s+"#, with: "", options: .regularExpression)
            }
        }
        return nil
    }

    private static func extractName(from lines: [String], excludingDosage: String) -> String? {
        let skipKeywords = ["rx", "prescription", "pharmacy", "refill", "qty", "quantity", "exp", "lot", "ndc", "take"]
        for line in lines {
            let lower = line.lowercased()
            if skipKeywords.contains(where: { lower.contains($0) }) { continue }
            if !excludingDosage.isEmpty, lower.contains(excludingDosage.lowercased()) {
                let cleaned = line.replacingOccurrences(
                    of: excludingDosage,
                    with: "",
                    options: .caseInsensitive
                ).trimmingCharacters(in: .whitespacesAndNewlines)
                if cleaned.count >= 3 { return cleaned }
                continue
            }
            // Prefer lines that look like drug names (letters, maybe spaces/hyphens).
            let letters = line.filter(\.isLetter)
            if letters.count >= 3, letters.count >= line.count / 2 {
                return line
            }
        }
        return nil
    }
}
