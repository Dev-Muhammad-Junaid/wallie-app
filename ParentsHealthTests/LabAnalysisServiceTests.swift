import XCTest
@testable import ParentsHealth

final class LabAnalysisServiceTests: XCTestCase {
    func testLocalProviderParsesText() async throws {
        let provider = LocalLabAnalysisProvider()
        let result = try await provider.analyze(
            text: "Glucose: 110 mg/dL\nHbA1c: 5.9 %",
            parentName: "Margaret"
        )
        XCTAssertEqual(result.providerName, "On-Device")
        XCTAssertFalse(result.results.isEmpty)
        XCTAssertTrue(result.insights.contains("Margaret"))
    }

    func testRemoteProviderFallsBackWithoutEndpoint() async throws {
        let provider = RemoteLabAnalysisProvider(endpoint: "", apiKey: "")
        let result = try await provider.analyze(text: "Glucose: 130 mg/dL", parentName: "Dad")
        XCTAssertFalse(result.results.isEmpty)
        let glucose = result.results.first { $0.testKey == .glucose }
        XCTAssertEqual(glucose?.value, 130)
    }

    func testLabTestKeyResolve() {
        XCTAssertEqual(LabTestKey.resolve(from: "fasting glucose"), .glucose)
        XCTAssertEqual(LabTestKey.resolve(from: "LDL cholesterol"), .ldl)
        XCTAssertNil(LabTestKey.resolve(from: "unknown marker"))
    }
}
