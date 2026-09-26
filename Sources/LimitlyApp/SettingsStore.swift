import Combine
import LimitlyCore
import Foundation
import ServiceManagement
import os

enum RefreshInterval: Double, CaseIterable, Identifiable, Sendable {
    case thirtySeconds = 30
    case oneMinute = 60
    case fiveMinutes = 300

    var id: Double { rawValue }

    var label: String {
        switch self {
        case .thirtySeconds:
            return "30초"
        case .oneMinute:
            return "1분"
        case .fiveMinutes:
            return "5분"
        }
    }
}

enum MenuBarDisplayMode: String, CaseIterable, Identifiable, Sendable {
    case icon
    case content

    var id: String { rawValue }

    var label: String {
        switch self {
        case .icon:
            return "아이콘"
        case .content:
            return "수치"
        }
    }
}

@MainActor
final class SettingsStore: ObservableObject {
    private enum Key {
        static let launchAtLogin = "settings.launchAtLogin"
        static let refreshInterval = "settings.refreshInterval"
        static let showMenuBar = "settings.showMenuBar"
        static let menuBarDisplayMode = "settings.menuBarDisplayMode"
        static let showFiveHour = "settings.showFiveHour"
        static let showWeekly = "settings.showWeekly"
    }

    private let defaults: UserDefaults
    private let logger = Logger(subsystem: "local.limitly.usage-menubar", category: "settings")

    @Published var launchAtLogin: Bool {
        didSet { defaults.set(launchAtLogin, forKey: Key.launchAtLogin); syncLaunchAtLogin() }
    }

    @Published var refreshInterval: RefreshInterval {
        didSet { defaults.set(refreshInterval.rawValue, forKey: Key.refreshInterval) }
    }

    @Published var showMenuBar: Bool {
        didSet { defaults.set(showMenuBar, forKey: Key.showMenuBar) }
    }

    @Published var menuBarDisplayMode: MenuBarDisplayMode {
        didSet { defaults.set(menuBarDisplayMode.rawValue, forKey: Key.menuBarDisplayMode) }
    }

    @Published var showFiveHour: Bool {
        didSet { defaults.set(showFiveHour, forKey: Key.showFiveHour) }
    }

    @Published var showWeekly: Bool {
        didSet { defaults.set(showWeekly, forKey: Key.showWeekly) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.launchAtLogin = defaults.object(forKey: Key.launchAtLogin) as? Bool ?? LimitlySettingsDefaults.launchAtLogin
        self.refreshInterval = RefreshInterval(rawValue: defaults.double(forKey: Key.refreshInterval)) ?? RefreshInterval(rawValue: LimitlySettingsDefaults.refreshIntervalSeconds) ?? .oneMinute
        self.showMenuBar = defaults.object(forKey: Key.showMenuBar) as? Bool ?? LimitlySettingsDefaults.showMenuBar
        self.menuBarDisplayMode = MenuBarDisplayMode(rawValue: defaults.string(forKey: Key.menuBarDisplayMode) ?? LimitlySettingsDefaults.menuBarDisplayModeRawValue) ?? .content
        self.showFiveHour = defaults.object(forKey: Key.showFiveHour) as? Bool ?? LimitlySettingsDefaults.showFiveHour
        self.showWeekly = defaults.object(forKey: Key.showWeekly) as? Bool ?? LimitlySettingsDefaults.showWeekly
    }

    func syncLaunchAtLogin() {
        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            logger.error("Unable to update login item: \(error.localizedDescription, privacy: .public)")
        }
    }
}
