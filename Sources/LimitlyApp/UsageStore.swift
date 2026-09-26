import Combine
import Foundation
import LimitlyCore
import os

struct LimitDisplayState: Equatable, Sendable {
    let kind: RateLimitKind
    let remainingPercent: Double?
    let resetsAt: Date?
}

struct UsageSnapshot: Equatable, Sendable {
    var fiveHour: LimitDisplayState?
    var weekly: LimitDisplayState?
    var lastSuccessfulFetch: Date?

    static let empty = UsageSnapshot(fiveHour: nil, weekly: nil, lastSuccessfulFetch: nil)
}

enum UsageConnectionState: Equatable {
    case idle
    case refreshing
    case connected
    case needsLogin
    case failed(String)

    var label: String {
        switch self {
        case .idle:
            return "조회 대기 중"
        case .refreshing:
            return "조회 중"
        case .connected:
            return "연결됨"
        case .needsLogin:
            return "Codex 로그인 필요"
        case .failed(let message):
            return message.isEmpty ? "사용량 정보를 가져올 수 없습니다." : message
        }
    }

    var errorMessage: String? {
        switch self {
        case .needsLogin, .failed:
            return label
        case .idle, .refreshing, .connected:
            return nil
        }
    }

    var hasError: Bool {
        errorMessage != nil
    }
}

@MainActor
final class UsageStore: ObservableObject {
    @Published private(set) var snapshot = UsageSnapshot.empty
    @Published private(set) var state: UsageConnectionState = .idle
    @Published private(set) var isRefreshing = false

    private let provider: RateLimitProvider
    private let logger = Logger(subsystem: "local.limitly.usage-menubar", category: "usage")
    private var scheduledTask: Task<Void, Never>?

    init(provider: RateLimitProvider = CodexAppServerClient()) {
        self.provider = provider
    }

    deinit {
        scheduledTask?.cancel()
    }

    func start(interval: TimeInterval) {
        schedule(interval: interval)
        refresh()
    }

    func updateInterval(_ interval: TimeInterval) {
        schedule(interval: interval)
    }

    func refresh() {
        guard !isRefreshing else { return }
        isRefreshing = true
        state = .refreshing

        Task { [weak self] in
            guard let self else { return }
            do {
                let result = try await provider.readRateLimits()
                let fiveHour = Self.displayState(for: .fiveHour, in: result)
                let weekly = Self.displayState(for: .weekly, in: result)
                guard fiveHour != nil || weekly != nil else {
                    state = .failed("사용량 정보를 가져올 수 없습니다.")
                    logger.error("Rate limit response did not contain a supported window")
                    isRefreshing = false
                    return
                }

                let now = Date()
                snapshot = UsageSnapshot(
                    fiveHour: fiveHour,
                    weekly: weekly,
                    lastSuccessfulFetch: now
                )
                state = .connected
                logger.debug("Rate limits refreshed")
            } catch let error as CodexClientError {
                state = error == .notAuthenticated ? .needsLogin : .failed(error.localizedDescription)
                logger.error("Rate limit refresh failed: \(error.localizedDescription, privacy: .public)")
            } catch {
                state = .failed(error.localizedDescription)
                logger.error("Rate limit refresh failed: \(error.localizedDescription, privacy: .public)")
            }
            isRefreshing = false
        }
    }

    private func schedule(interval: TimeInterval) {
        scheduledTask?.cancel()
        scheduledTask = Task { [weak self] in
            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                } catch {
                    return
                }
                guard !Task.isCancelled else { return }
                self?.refresh()
            }
        }
    }

    private static func displayState(for kind: RateLimitKind, in result: RateLimitsResult) -> LimitDisplayState? {
        guard let window = result.window(for: kind) else { return nil }
        return LimitDisplayState(
            kind: kind,
            remainingPercent: window.remainingPercent,
            resetsAt: window.resetsAt.map(Date.init(timeIntervalSince1970:))
        )
    }
}
