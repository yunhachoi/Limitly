import Foundation

public enum RateLimitKind: String, CaseIterable, Sendable {
    case fiveHour
    case weekly

    public var title: String {
        switch self {
        case .fiveHour:
            return "5시간 한도"
        case .weekly:
            return "주간 한도"
        }
    }

    public var expectedWindowDurationMins: Int {
        switch self {
        case .fiveHour:
            return 5 * 60
        case .weekly:
            return 7 * 24 * 60
        }
    }
}

public struct RateLimitWindow: Codable, Equatable, Sendable {
    public let usedPercent: Double?
    public let windowDurationMins: Int?
    public let resetsAt: TimeInterval?

    public init(usedPercent: Double?, windowDurationMins: Int?, resetsAt: TimeInterval?) {
        self.usedPercent = usedPercent
        self.windowDurationMins = windowDurationMins
        self.resetsAt = resetsAt
    }

    public var remainingPercent: Double? {
        RateLimitMath.remainingPercent(usedPercent: usedPercent)
    }
}

public struct RateLimitBucket: Codable, Equatable, Sendable {
    public let limitId: String?
    public let limitName: String?
    public let primary: RateLimitWindow?
    public let secondary: RateLimitWindow?

    public init(
        limitId: String?,
        limitName: String?,
        primary: RateLimitWindow?,
        secondary: RateLimitWindow?
    ) {
        self.limitId = limitId
        self.limitName = limitName
        self.primary = primary
        self.secondary = secondary
    }

    fileprivate var windows: [RateLimitWindow] {
        [primary, secondary].compactMap { $0 }
    }
}

public struct RateLimitsResult: Codable, Equatable, Sendable {
    public let rateLimits: RateLimitBucket?
    public let rateLimitsByLimitId: [String: RateLimitBucket]?

    public init(
        rateLimits: RateLimitBucket?,
        rateLimitsByLimitId: [String: RateLimitBucket]?
    ) {
        self.rateLimits = rateLimits
        self.rateLimitsByLimitId = rateLimitsByLimitId
    }

    /// Select a window by its documented duration instead of assuming that
    /// `primary` always means five hours or `secondary` always means weekly.
    public func window(for kind: RateLimitKind) -> RateLimitWindow? {
        let targetDuration = kind.expectedWindowDurationMins

        if let map = rateLimitsByLimitId {
            let entries = map.sorted { lhs, rhs in
                let lhsIsCodex = lhs.key == "codex" || lhs.value.limitId == "codex"
                let rhsIsCodex = rhs.key == "codex" || rhs.value.limitId == "codex"
                if lhsIsCodex != rhsIsCodex {
                    return lhsIsCodex
                }
                return lhs.key < rhs.key
            }

            for (_, bucket) in entries {
                if let match = bucket.windows.first(where: { $0.windowDurationMins == targetDuration }) {
                    return match
                }
            }
        }

        return rateLimits?.windows.first(where: { $0.windowDurationMins == targetDuration })
    }
}

public enum RateLimitMath {
    public static func remainingPercent(usedPercent: Double?) -> Double? {
        guard let usedPercent, usedPercent.isFinite else {
            return nil
        }
        return min(100, max(0, 100 - usedPercent))
    }
}

public enum RemainingTimeFormatter {
    public static func string(until resetDate: Date, now: Date = Date()) -> String {
        let secondsRemaining = resetDate.timeIntervalSince(now)
        guard secondsRemaining > 0 else {
            return "초기화 확인 중"
        }

        guard secondsRemaining >= 60 else {
            return "1분 미만"
        }

        let minutes = Int(ceil(secondsRemaining / 60))

        if minutes > 24 * 60 {
            let days = minutes / (24 * 60)
            let hours = (minutes % (24 * 60)) / 60
            let remainder = minutes % 60
            return "\(days)일 \(hours)시간 \(remainder)분"
        }

        let hours = minutes / 60
        let remainder = minutes % 60
        return "\(hours)시간 \(remainder)분"
    }
}
