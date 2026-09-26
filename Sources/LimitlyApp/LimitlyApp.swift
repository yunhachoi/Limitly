import AppKit
import Foundation
import LimitlyCore

@main
struct LimitlyApp {
    static func main() {
        if CommandLine.arguments.contains("--probe") {
            runConnectionProbe()
            return
        }

        guard shouldStartSingleInstance() else { return }

        let application = NSApplication.shared
        let delegate = AppDelegate()
        application.delegate = delegate
        application.run()
    }

    private static func shouldStartSingleInstance() -> Bool {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else { return true }
        let currentProcessID = ProcessInfo.processInfo.processIdentifier
        let existingInstances = NSRunningApplication.runningApplications(
            withBundleIdentifier: bundleIdentifier
        ).filter { $0.processIdentifier != currentProcessID }

        guard let existingInstance = existingInstances.first else { return true }
        existingInstance.activate(options: [.activateIgnoringOtherApps])
        return false
    }

    private static func runConnectionProbe() {
        let group = DispatchGroup()
        group.enter()
        Task.detached(priority: .utility) {
            defer { group.leave() }
            do {
                let result = try await CodexAppServerClient().readRateLimits()
                var windows: [String: [String: Double]] = [:]
                for kind in RateLimitKind.allCases {
                    if let window = result.window(for: kind) {
                        var values: [String: Double] = [:]
                        if let usedPercent = window.usedPercent {
                            values["usedPercent"] = usedPercent
                        }
                        if let remainingPercent = window.remainingPercent {
                            values["remainingPercent"] = remainingPercent
                        }
                        windows[kind.rawValue] = values
                    }
                }
                print("Limitly Codex probe: connected; windows=\(windows)")
            } catch {
                print("Limitly Codex probe: failed; reason=\(error.localizedDescription)")
            }
        }
        group.wait()
    }
}
