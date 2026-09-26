import XCTest
@testable import LimitlyCore

final class RemainingTimeFormatterTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

    func testLessThanOneMinute() {
        let now = Date(timeIntervalSince1970: 1_000)
        XCTAssertEqual(RemainingTimeFormatter.string(until: now.addingTimeInterval(59), now: now), "1분 미만")
    }

    func testExactlyTwentyFourHoursUsesHourFormat() {
        let now = Date(timeIntervalSince1970: 1_000)
        XCTAssertEqual(RemainingTimeFormatter.string(until: now.addingTimeInterval(24 * 60 * 60), now: now), "24시간 0분")
    }

    func testWeeklyDurationOverTwentyFourHoursUsesDayFormat() {
        let now = Date(timeIntervalSince1970: 1_000)
        let seconds = (2 * 24 * 60 + 3 * 60 + 4) * 60
        XCTAssertEqual(RemainingTimeFormatter.string(until: now.addingTimeInterval(TimeInterval(seconds)), now: now), "2일 3시간 4분")
    }

    func testExpiredResetShowsCheckingState() {
        let now = Date(timeIntervalSince1970: 1_000)
        XCTAssertEqual(RemainingTimeFormatter.string(until: now.addingTimeInterval(-1), now: now), "초기화 확인 중")
    }
}
