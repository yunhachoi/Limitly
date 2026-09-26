import XCTest
@testable import LimitlyCore

final class RateLimitCalculatorTests: XCTestCase {
    func testRemainingPercentIsCalculatedAndClamped() {
        XCTAssertEqual(RateLimitMath.remainingPercent(usedPercent: 37.5), 62.5)
        XCTAssertEqual(RateLimitMath.remainingPercent(usedPercent: -5), 100)
        XCTAssertEqual(RateLimitMath.remainingPercent(usedPercent: 140), 0)
    }

    func testMissingUsageDoesNotBecomeZeroOrOneHundred() {
        XCTAssertNil(RateLimitMath.remainingPercent(usedPercent: nil))
    }

    func testSelectsFiveHourAndWeeklyWindowsByDuration() throws {
        let result = RateLimitsResult(
            rateLimits: nil,
            rateLimitsByLimitId: [
                "codex": RateLimitBucket(
                    limitId: "codex",
                    limitName: nil,
                    primary: RateLimitWindow(usedPercent: 25, windowDurationMins: 300, resetsAt: 1_800),
                    secondary: RateLimitWindow(usedPercent: 50, windowDurationMins: 10_080, resetsAt: 2_000)
                )
            ]
        )

        let fiveHour = try XCTUnwrap(result.window(for: .fiveHour))
        let weekly = try XCTUnwrap(result.window(for: .weekly))
        XCTAssertEqual(fiveHour.windowDurationMins, 300)
        XCTAssertEqual(weekly.windowDurationMins, 10_080)
        XCTAssertEqual(fiveHour.remainingPercent, 75)
        XCTAssertEqual(weekly.remainingPercent, 50)
    }
}
