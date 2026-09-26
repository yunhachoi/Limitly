import Foundation

private func check(_ condition: @autoclosure () -> Bool, _ message: String) {
    precondition(condition(), message)
}

check(LimitlySettingsDefaults.launchAtLogin, "new install launches at login")
check(LimitlySettingsDefaults.menuBarDisplayModeRawValue == "content", "new install uses numeric menu bar")
check(LimitlySettingsDefaults.refreshIntervalSeconds == 60, "default refresh interval")
check(LimitlySettingsDefaults.showMenuBar, "default menu bar visibility")
check(LimitlySettingsDefaults.showFiveHour, "default five-hour visibility")
check(LimitlySettingsDefaults.showWeekly, "default weekly visibility")

let locatorProbeDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
    .appendingPathComponent("limitly-locator-directory-probe", isDirectory: true)
try? FileManager.default.removeItem(at: locatorProbeDirectory)
try! FileManager.default.createDirectory(at: locatorProbeDirectory, withIntermediateDirectories: true)
check(
    !CodexExecutableLocator.isUsableExecutable(at: locatorProbeDirectory, fileManager: .default),
    "Codex locator rejects executable directories"
)
try? FileManager.default.removeItem(at: locatorProbeDirectory)

let locatorProbeRoot = URL(fileURLWithPath: NSTemporaryDirectory())
    .appendingPathComponent("limitly-locator-root-probe", isDirectory: true)
let locatorProbeExecutable = locatorProbeRoot
    .appendingPathComponent("future-layout/tools/codex")
try? FileManager.default.removeItem(at: locatorProbeRoot)
try! FileManager.default.createDirectory(
    at: locatorProbeExecutable.deletingLastPathComponent(),
    withIntermediateDirectories: true
)
FileManager.default.createFile(atPath: locatorProbeExecutable.path, contents: Data("#!/bin/sh\n".utf8))
try! FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: locatorProbeExecutable.path)
check(
    CodexExecutableLocator.locate(in: locatorProbeRoot, fileManager: .default)?.resolvingSymlinksInPath().path
        == locatorProbeExecutable.resolvingSymlinksInPath().path,
    "Codex locator searches below the fixed resource root"
)
try? FileManager.default.removeItem(at: locatorProbeRoot)

check(RateLimitMath.remainingPercent(usedPercent: 37.5) == 62.5, "remaining percent")
check(RateLimitMath.remainingPercent(usedPercent: -5) == 100, "lower clamp")
check(RateLimitMath.remainingPercent(usedPercent: 140) == 0, "upper clamp")
check(RateLimitMath.remainingPercent(usedPercent: nil) == nil, "missing percent")

let now = Date(timeIntervalSince1970: 1_000)
check(RemainingTimeFormatter.string(until: now.addingTimeInterval(59), now: now) == "1분 미만", "sub-minute")
check(RemainingTimeFormatter.string(until: now.addingTimeInterval(60), now: now) == "0시간 1분", "one minute")
check(RemainingTimeFormatter.string(until: now.addingTimeInterval(24 * 60 * 60), now: now) == "24시간 0분", "24 hours")
check(RemainingTimeFormatter.string(until: now.addingTimeInterval((2 * 24 * 60 + 3 * 60 + 4) * 60), now: now) == "2일 3시간 4분", "day format")
check(RemainingTimeFormatter.string(until: now.addingTimeInterval(-1), now: now) == "초기화 확인 중", "expired")

var seoulCalendar = Calendar(identifier: .gregorian)
seoulCalendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
let sampleDate = seoulCalendar.date(from: DateComponents(year: 2026, month: 9, day: 16, hour: 16, minute: 44, second: 20))!
check(
    DashboardDateFormatter.string(from: sampleDate, calendar: seoulCalendar) == "9월 16일 16:44:20",
    "month-day timestamp"
)

let bucket = RateLimitBucket(
    limitId: "codex",
    limitName: nil,
    primary: RateLimitWindow(usedPercent: 25, windowDurationMins: 300, resetsAt: 1_800),
    secondary: RateLimitWindow(usedPercent: 50, windowDurationMins: 10_080, resetsAt: 2_000)
)
let result = RateLimitsResult(rateLimits: nil, rateLimitsByLimitId: ["codex": bucket])
check(result.window(for: .fiveHour)?.remainingPercent == 75, "five-hour selection")
check(result.window(for: .weekly)?.remainingPercent == 50, "weekly selection")

var framer = JSONLFramer()
check(framer.append(Data(#"{"id":1,"result":{}"#.utf8)).isEmpty, "split line")
let lines = framer.append(Data("}\n{\"id\":2}\n".utf8))
check(lines.count == 2, "line count")
check(String(decoding: lines[0], as: UTF8.self) == #"{"id":1,"result":{}}"#, "first line")

let request = JSONRPCRequest.initialize(clientName: "limitly", version: "1.0.0")
let encodedRequest = try JSONEncoder().encode(request)
let requestObject = try JSONSerialization.jsonObject(with: encodedRequest) as! [String: Any]
check(requestObject["method"] as? String == "initialize", "initialize method")

let fixture = Data(#"{"id":6,"result":{"rateLimits":{"limitId":"codex","primary":{"usedPercent":25,"windowDurationMins":300,"resetsAt":1730947200},"secondary":{"usedPercent":42,"windowDurationMins":10080,"resetsAt":1730950800}},"rateLimitsByLimitId":{"codex":{"limitId":"codex","primary":{"usedPercent":25,"windowDurationMins":300,"resetsAt":1730947200},"secondary":null}}}}"#.utf8)
let response = try JSONDecoder().decode(JSONRPCResponse<RateLimitsResult>.self, from: fixture)
check(response.id == 6, "response id")
check(response.result?.window(for: .fiveHour)?.remainingPercent == 75, "decoded five-hour")
check(response.result?.window(for: .weekly)?.remainingPercent == 58, "decoded weekly")

let statusNow = Date(timeIntervalSince1970: 1_000)
check(
    MenuBarStatusFormatter.string(
        fiveHour: 58,
        fiveHourResetsAt: statusNow.addingTimeInterval(1_020),
        weekly: 77,
        weeklyResetsAt: statusNow.addingTimeInterval(6_000),
        now: statusNow
    ) == "5h 58% (0시간 17분)  W 77% (1시간 40분)",
    "menu bar status with reset times"
)
check(
    MenuBarStatusFormatter.string(
        fiveHour: 58,
        fiveHourResetsAt: statusNow.addingTimeInterval(120),
        weekly: nil,
        weeklyResetsAt: nil,
        now: statusNow
    ) == "5h 58% (0시간 2분)",
    "single menu bar status with reset time"
)
check(
    MenuBarStatusFormatter.string(
        fiveHour: nil,
        fiveHourResetsAt: nil,
        weekly: nil,
        weeklyResetsAt: nil,
        now: statusNow
    ) == "Limitly",
    "empty menu bar status"
)

check(
    MenuBarPopoverPolicy.action(popoverIsShown: false) == .showDashboard,
    "hidden popover requests presentation"
)
check(
    MenuBarPopoverPolicy.action(popoverIsShown: true) == .hideDashboard,
    "shown popover requests dismissal"
)

print("Limitly core checks passed")
