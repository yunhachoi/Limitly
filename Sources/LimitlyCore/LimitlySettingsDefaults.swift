import Foundation

/// Defaults used when a Limitly setting has not been stored yet.
///
/// Keeping these values in the core target makes the first-run contract
/// testable without constructing AppKit or registering a login item.
public enum LimitlySettingsDefaults {
    public static let launchAtLogin = true
    public static let refreshIntervalSeconds: Double = 60
    public static let showMenuBar = true
    public static let menuBarDisplayModeRawValue = "content"
    public static let showFiveHour = true
    public static let showWeekly = true
}
