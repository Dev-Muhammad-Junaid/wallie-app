import XCTest
@testable import ParentsHealth

final class MedicationOCRServiceTests: XCTestCase {
    func testParsesNameAndDosageFromLabelText() {
        let text = """
        Rx
        Lisinopril
        10 mg
        Take one tablet by mouth daily
        """
        let parsed = MedicationOCRService.parse(text: text)
        XCTAssertTrue(parsed.name.localizedCaseInsensitiveContains("Lisinopril"))
        XCTAssertTrue(parsed.dosage.localizedCaseInsensitiveContains("10"))
        XCTAssertTrue(parsed.dosage.localizedCaseInsensitiveContains("mg"))
    }

    func testParsesIUDosage() {
        let text = """
        Vitamin D3
        2000 IU Softgels
        """
        let parsed = MedicationOCRService.parse(text: text)
        XCTAssertFalse(parsed.dosage.isEmpty)
        XCTAssertTrue(parsed.dosage.localizedCaseInsensitiveContains("2000"))
    }
}
