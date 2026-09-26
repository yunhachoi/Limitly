import Foundation

/// Formats the last successful dashboard refresh as month, day, and time.
public enum DashboardDateFormatter {
    public static func string(from date: Date, calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.calendar = calendar
        formatter.dateFormat = "M월 d일 HH:mm:ss"
        return formatter.string(from: date)
    }
}
