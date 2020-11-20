import XCTest
@testable import Speechly

final class SpeechlyTests: XCTestCase {
    func testExample() {
        let transcript = SpeechTranscript(index: 0, value: "test", startOffset: 0, endOffset: 1, isFinal: true)
        XCTAssertEqual(transcript.value, "test")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
