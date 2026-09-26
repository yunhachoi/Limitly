import Foundation

/// The action a menu-bar click should take for the dashboard popover.
public enum MenuBarPopoverAction: Equatable, Sendable {
    case showDashboard
    case hideDashboard
}

/// Keeps the menu-bar toggle decision independent from AppKit event plumbing.
public enum MenuBarPopoverPolicy {
    public static func action(popoverIsShown: Bool) -> MenuBarPopoverAction {
        popoverIsShown ? .hideDashboard : .showDashboard
    }
}
