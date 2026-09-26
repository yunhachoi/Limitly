import AppKit
import Combine
import LimitlyCore
import SwiftUI
import os

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let logger = Logger(subsystem: "local.limitly.usage-menubar", category: "app")
    private let settings = SettingsStore()
    private let usageStore = UsageStore()
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var settingsWindowController: NSWindowController?
    private var aboutWindowController: NSWindowController?
    private var cancellables: Set<AnyCancellable> = []
    private var statusTimer: Timer?
    private var popoverEventMonitors: [Any] = []
    private var popoverWindowObservers: [NSObjectProtocol] = []
    private var suppressPopoverDismissalUntil = Date.distantPast

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        // Apply the persisted/default preference to the actual login item on
        // launch. Property observers do not run for values loaded in init.
        settings.syncLaunchAtLogin()
        configureStatusItem()
        observeState()
        usageStore.start(interval: settings.refreshInterval.rawValue)
        statusTimer = Timer.scheduledTimer(
            timeInterval: 30,
            target: self,
            selector: #selector(statusTimerFired),
            userInfo: nil,
            repeats: true
        )

        if !settings.showMenuBar {
            showSettings()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag && !settings.showMenuBar {
            showSettings()
        }
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        statusTimer?.invalidate()
        statusTimer = nil
        removePopoverDismissalMonitors()
        removePopoverWindowObservers()
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem = item
        item.button?.target = self
        item.button?.action = #selector(togglePopover(_:))
        item.button?.imagePosition = .imageOnly
        item.button?.setAccessibilityLabel("Limitly")
        item.button?.toolTip = "Limitly 사용 한도"

        let controller = NSHostingController(
            rootView: DashboardView(
                store: usageStore,
                settings: settings,
                onSettings: { [weak self] in self?.showSettings() },
                onAbout: { [weak self] in self?.showAbout() },
                onQuit: { NSApp.terminate(nil) }
            )
        )
        let panel = NSPopover()
        panel.contentViewController = controller
        panel.contentSize = NSSize(width: 350, height: 350)
        panel.behavior = .transient
        panel.animates = false
        popover = panel
        installPopoverDismissalMonitors()
        updateStatusItem()
    }

    private func observeState() {
        settings.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.usageStore.updateInterval(self?.settings.refreshInterval.rawValue ?? 60)
                    self?.updateStatusItem()
                }
            }
            .store(in: &cancellables)

        usageStore.$snapshot
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.updateStatusItem() }
            .store(in: &cancellables)

        usageStore.$state
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.updateStatusItem() }
            .store(in: &cancellables)
    }

    @objc private func togglePopover(_ sender: Any?) {
        guard let button = statusItem?.button, let popover else { return }
        logger.notice("Status button click frame=\(NSStringFromRect(button.window?.frame ?? .zero), privacy: .public) button=\(NSStringFromRect(button.frame), privacy: .public)")
        switch MenuBarPopoverPolicy.action(popoverIsShown: popover.isShown) {
        case .hideDashboard:
            logger.notice("Menu bar click: hiding dashboard")
            popover.performClose(sender)
        case .showDashboard:
            logger.notice("Menu bar click: showing dashboard")
            suppressPopoverDismissalUntil = Date().addingTimeInterval(0.35)
            // An accessory application is normally inactive. Activate it
            // before showing the transient popover so AppKit can later use
            // deactivation as the reliable outside-app dismissal signal.
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            guard let popoverWindow = popover.contentViewController?.view.window else { return }
            popoverWindow.hidesOnDeactivate = true
            installPopoverWindowObservers(for: popoverWindow)
        }
    }

    private func closePopover() {
        guard popover?.isShown == true else { return }
        popover?.performClose(nil)
    }

    private func installPopoverDismissalMonitors() {
        guard popoverEventMonitors.isEmpty else { return }

        let localMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown, .keyDown]
        ) { [weak self] event in
            guard let self, let popover = self.popover, popover.isShown else { return event }

            if event.type == .keyDown {
                if event.keyCode == 53 {
                    self.closePopover()
                    return nil
                }
                return event
            }

            let popoverWindow = popover.contentViewController?.view.window
            let clickedInsidePopover = event.window === popoverWindow
            if !clickedInsidePopover && !self.isPointerOverStatusItem {
                self.closePopover()
            }
            return event
        }

        let globalMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self,
                      self.popover?.isShown == true,
                      Date() >= self.suppressPopoverDismissalUntil else { return }
                self.closePopover()
            }
        }

        popoverEventMonitors = [localMonitor as Any, globalMonitor as Any]
    }

    private func removePopoverDismissalMonitors() {
        for monitor in popoverEventMonitors {
            NSEvent.removeMonitor(monitor)
        }
        popoverEventMonitors.removeAll()
    }

    private func installPopoverWindowObservers(for window: NSWindow) {
        guard popoverWindowObservers.isEmpty else { return }

        let resignKey = NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            DispatchQueue.main.async { [weak self] in
                guard let self,
                      Date() >= self.suppressPopoverDismissalUntil else { return }
                self.closePopover()
            }
        }

        let resignMain = NotificationCenter.default.addObserver(
            forName: NSWindow.didResignMainNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            DispatchQueue.main.async { [weak self] in
                guard let self,
                      Date() >= self.suppressPopoverDismissalUntil else { return }
                self.closePopover()
            }
        }

        popoverWindowObservers = [resignKey, resignMain]
    }

    private func removePopoverWindowObservers() {
        for observer in popoverWindowObservers {
            NotificationCenter.default.removeObserver(observer)
        }
        popoverWindowObservers.removeAll()
    }

    private var isPointerOverStatusItem: Bool {
        guard let button = statusItem?.button, let window = button.window else { return false }
        return window.frame.contains(NSEvent.mouseLocation)
    }

    private func updateStatusItem() {
        guard let item = statusItem, let button = item.button else { return }
        item.isVisible = settings.showMenuBar
        let errorMessage = usageStore.state.errorMessage
        button.setAccessibilityLabel(errorMessage.map { "Limitly 오류: \($0)" } ?? "Limitly")
        button.toolTip = errorMessage.map { "Limitly 오류: \($0)" } ?? "Limitly 사용 한도"

        switch settings.menuBarDisplayMode {
        case .icon:
            button.title = ""
            button.image = loadMenuBarImage(
                for: button.effectiveAppearance,
                isError: usageStore.state.hasError
            )
            button.image?.isTemplate = false
            button.imageScaling = .scaleProportionallyDown
        case .content:
            button.image = nil
            button.title = statusText()
            button.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        }
    }

    private func statusText() -> String {
        if let errorMessage = usageStore.state.errorMessage {
            return "오류: \(errorMessage)"
        }
        return MenuBarStatusFormatter.string(
            fiveHour: settings.showFiveHour ? usageStore.snapshot.fiveHour?.remainingPercent : nil,
            fiveHourResetsAt: settings.showFiveHour ? usageStore.snapshot.fiveHour?.resetsAt : nil,
            weekly: settings.showWeekly ? usageStore.snapshot.weekly?.remainingPercent : nil,
            weeklyResetsAt: settings.showWeekly ? usageStore.snapshot.weekly?.resetsAt : nil,
            now: Date()
        )
    }

    private func loadMenuBarImage(for appearance: NSAppearance, isError: Bool) -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18))
        appearance.performAsCurrentDrawingAppearance {
            image.lockFocus()

            let center = NSPoint(x: 8.5, y: 8.5)
            let radius: CGFloat = 5.8
            let mark = NSBezierPath()
            mark.appendArc(
                withCenter: center,
                radius: radius,
                startAngle: 42,
                endAngle: 318,
                clockwise: false
            )
            mark.lineWidth = 2.35
            mark.lineCapStyle = .round
            (isError ? NSColor.systemRed : NSColor.labelColor).setStroke()
            mark.stroke()

            let dotRadius: CGFloat = 1.65
            let dotRect = NSRect(
                x: center.x + 3.7,
                y: center.y + 3.5,
                width: dotRadius * 2,
                height: dotRadius * 2
            )
            let dotColor = isError
                ? NSColor.systemRed
                : NSColor(calibratedRed: 10 / 255, green: 132 / 255, blue: 255 / 255, alpha: 1)
            dotColor.setFill()
            NSBezierPath(ovalIn: dotRect).fill()

            image.unlockFocus()
        }
        image.isTemplate = false
        image.accessibilityDescription = "Limitly"
        return image
    }

    @objc private func statusTimerFired() {
        updateStatusItem()
    }

    func showSettings() {
        closePopover()
        if settingsWindowController == nil {
            let view = SettingsView(settings: settings)
            let controller = NSHostingController(rootView: view)
            let window = NSWindow(contentViewController: controller)
            window.title = "설정"
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            window.center()
            settingsWindowController = NSWindowController(window: window)
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindowController?.showWindow(nil)
        settingsWindowController?.window?.makeKeyAndOrderFront(nil)
    }

    private func showAbout() {
        closePopover()
        if aboutWindowController == nil {
            let controller = NSHostingController(rootView: AboutView())
            let window = NSWindow(contentViewController: controller)
            window.title = "정보"
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            window.center()
            aboutWindowController = NSWindowController(window: window)
        }
        NSApp.activate(ignoringOtherApps: true)
        aboutWindowController?.showWindow(nil)
        aboutWindowController?.window?.makeKeyAndOrderFront(nil)
    }
}
