import XCTest
@testable import LimitlyCore

final class MenuBarStatusFormatterTests: XCTestCase {
    func testFormatsBothWindowsWithResetTimes() {
        let now = Date(timeIntervalSince1970: 1_000)
        XCTAssertEqual(
            MenuBarStatusFormatter.string(
                fiveHour: 58,
                fiveHourResetsAt: now.addingTimeInterval(1_020),
                weekly: 77,
                weeklyResetsAt: now.addingTimeInterval(6_000),
                now: now
            ),
            "5h 58% (0시간 17분)  W 77% (1시간 40분)"
        )
    }

    func testOmitsUnavailableWindow() {
        let now = Date(timeIntervalSince1970: 1_000)
        XCTAssertEqual(
            MenuBarStatusFormatter.string(
                fiveHour: 58,
                fiveHourResetsAt: now.addingTimeInterval(120),
                weekly: nil,
                weeklyResetsAt: nil,
                now: now
            ),
            "5h 58% (0시간 2분)"
        )
    }

    func testUsesBrandNameWhenNoWindowIsAvailable() {
        XCTAssertEqual(
            MenuBarStatusFormatter.string(
                fiveHour: nil,
                fiveHourResetsAt: nil,
                weekly: nil,
                weeklyResetsAt: nil,
                now: Date(timeIntervalSince1970: 1_000)
            ),
            "Limitly"
        )
    }
}
