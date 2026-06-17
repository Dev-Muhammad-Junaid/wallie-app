import Foundation
import UIKit

struct LabAnalysisResult: Equatable {
    let rawText: String
    let results: [ParsedLabResult]
    let labDate: Date?
    let insights: String
    let providerName: String
}

/// Pluggable analysis — swap local OCR/parser today for a remote API tomorrow.
protocol LabAnalysisProviding {
    var providerName: String { get }
    func analyze(text: String, parentName: String) async throws -> LabAnalysisResult
    func analyze(image: UIImage, parentName: String) async throws -> LabAnalysisResult
}

struct LocalLabAnalysisProvider: LabAnalysisProviding {
    let providerName = "On-Device"

    func analyze(text: String, parentName: String) async throws -> LabAnalysisResult {
        let parsed = LabReportParser.parse(text: text)
        let labDate = LabReportParser.extractLabDate(from: text)
        let insights = LabReportParser.generateInsights(results: parsed, parentName: parentName)
        return LabAnalysisResult(
            rawText: text,
            results: parsed,
            labDate: labDate,
            insights: insights,
            providerName: providerName
        )
    }

    func analyze(image: UIImage, parentName: String) async throws -> LabAnalysisResult {
        let text = try await LabReportOCRService.recognizeText(from: image)
        return try await analyze(text: text, parentName: parentName)
    }
}

/// Remote API stub — wire your endpoint in Settings when ready.
struct RemoteLabAnalysisProvider: LabAnalysisProviding {
    let endpoint: String
    let apiKey: String
    let providerName = "AI API"

    func analyze(text: String, parentName: String) async throws -> LabAnalysisResult {
        // Future: POST text to your API, decode structured JSON into ParsedLabResult[]
        // For now, fall back to local parsing so the app always works offline.
        guard !endpoint.isEmpty else {
            return try await LocalLabAnalysisProvider().analyze(text: text, parentName: parentName)
        }

        // Placeholder for API integration — replace body when endpoint is live.
        if let apiResult = try? await callAPI(text: text, parentName: parentName) {
            return apiResult
        }
        return try await LocalLabAnalysisProvider().analyze(text: text, parentName: parentName)
    }

    func analyze(image: UIImage, parentName: String) async throws -> LabAnalysisResult {
        let text = try await LabReportOCRService.recognizeText(from: image)
        return try await analyze(text: text, parentName: parentName)
    }

    private func callAPI(text: String, parentName: String) async throws -> LabAnalysisResult {
        guard let url = URL(string: endpoint) else {
            throw LabAnalysisError.invalidEndpoint
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        let body: [String: String] = [
            "text": text,
            "parentName": parentName
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw LabAnalysisError.apiFailed
        }

        return try decodeAPIResponse(data: data, rawText: text, parentName: parentName)
    }

    private func decodeAPIResponse(data: Data, rawText: String, parentName: String) throws -> LabAnalysisResult {
        struct APIPayload: Decodable {
            struct Item: Decodable {
                let testKey: String
                let testName: String
                let value: Double
                let unit: String
                let referenceRange: String
                let isAbnormal: Bool
            }
            let results: [Item]
            let labDate: String?
            let insights: String?
        }

        let payload = try JSONDecoder().decode(APIPayload.self, from: data)
        let parsed = payload.results.map {
            ParsedLabResult(
                testKey: LabTestKey(rawValue: $0.testKey) ?? .glucose,
                testName: $0.testName,
                value: $0.value,
                unit: $0.unit,
                referenceRange: $0.referenceRange,
                isAbnormal: $0.isAbnormal
            )
        }

        let labDate = payload.labDate.flatMap { ISO8601DateFormatter().date(from: $0) }
            ?? LabReportParser.extractLabDate(from: rawText)

        return LabAnalysisResult(
            rawText: rawText,
            results: parsed,
            labDate: labDate,
            insights: payload.insights ?? LabReportParser.generateInsights(results: parsed, parentName: parentName),
            providerName: providerName
        )
    }
}

enum LabAnalysisService {
    static func provider() -> LabAnalysisProviding {
        if AppSettings.useRemoteLabAPI,
           let endpoint = AppSettings.labAPIEndpoint,
           !endpoint.isEmpty {
            return RemoteLabAnalysisProvider(endpoint: endpoint, apiKey: AppSettings.labAPIKey)
        }
        return LocalLabAnalysisProvider()
    }
}

enum LabAnalysisError: LocalizedError {
    case invalidEndpoint
    case apiFailed
    case noTextFound

    var errorDescription: String? {
        switch self {
        case .invalidEndpoint: return "Lab API endpoint URL is invalid."
        case .apiFailed: return "Lab API request failed. Saved using on-device analysis instead."
        case .noTextFound: return "No text found in the image. Try a clearer photo or paste text."
        }
    }
}
