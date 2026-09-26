import Foundation

/// Formats the status shown beside the menu-bar icon.
public enum MenuBarStatusFormatter {
    public static func string(
        fiveHour: Double?,
        fiveHourResetsAt: Date?,
        weekly: Double?,
        weeklyResetsAt: Date?,
        now: Date = Date()
    ) -> String {
        var parts: [String] = []
        if let fiveHour = component(
            label: "5h",
            value: fiveHour,
            resetsAt: fiveHourResetsAt,
            now: now
        ) {
            parts.append(fiveHour)
        }
        if let weekly = component(
            label: "W",
            value: weekly,
            resetsAt: weeklyResetsAt,
            now: now
        ) {
            parts.append(weekly)
        }
        return parts.isEmpty ? "Limitly" : parts.joined(separator: "  ")
    }

    private static func component(
        label: String,
        value: Double?,
        resetsAt: Date?,
        now: Date
    ) -> String? {
        guard let value = format(value) else { return nil }
        guard let resetsAt else {
            return "\(label) \(value)%"
        }
        let remaining = RemainingTimeFormatter.string(until: resetsAt, now: now)
        return "\(label) \(value)% (\(remaining))"
    }

    private static func format(_ value: Double?) -> String? {
        guard let value, value.isFinite else { return nil }
        return String(Int(min(100, max(0, value)).rounded()))
    }
}
