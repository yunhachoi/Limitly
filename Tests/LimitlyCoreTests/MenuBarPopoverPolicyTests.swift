import XCTest
@testable import LimitlyCore

final class MenuBarPopoverPolicyTests: XCTestCase {
    func testHiddenPopoverRequestsDashboardPresentation() {
        XCTAssertEqual(
            MenuBarPopoverPolicy.action(popoverIsShown: false),
            .showDashboard
        )
    }

    func testShownPopoverRequestsDashboardDismissal() {
        XCTAssertEqual(
            MenuBarPopoverPolicy.action(popoverIsShown: true),
            .hideDashboard
        )
    }
}
