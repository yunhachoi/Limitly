import XCTest
@testable import LimitlyCore

final class SettingsDefaultsTests: XCTestCase {
    func testNewInstallUsesNumericMenuBarAndLaunchAtLogin() {
        XCTAssertTrue(LimitlySettingsDefaults.launchAtLogin)
        XCTAssertEqual(LimitlySettingsDefaults.menuBarDisplayModeRawValue, "content")
    }

    func testOtherNewInstallDefaultsRemainUnchanged() {
        XCTAssertEqual(LimitlySettingsDefaults.refreshIntervalSeconds, 60)
        XCTAssertTrue(LimitlySettingsDefaults.showMenuBar)
        XCTAssertTrue(LimitlySettingsDefaults.showFiveHour)
        XCTAssertTrue(LimitlySettingsDefaults.showWeekly)
    }
}
