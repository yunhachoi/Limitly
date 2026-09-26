import XCTest
@testable import LimitlyCore

final class DashboardDateFormatterTests: XCTestCase {
    func testFormatsMonthDayAndTimeInKorean() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
        let date = calendar.date(
            from: DateComponents(year: 2026, month: 9, day: 16, hour: 16, minute: 44, second: 20)
        )!

        XCTAssertEqual(
            DashboardDateFormatter.string(from: date, calendar: calendar),
            "9월 16일 16:44:20"
        )
    }
}
