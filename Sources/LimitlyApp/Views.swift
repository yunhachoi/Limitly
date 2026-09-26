import AppKit
import LimitlyCore
import SwiftUI

struct DashboardView: View {
    @ObservedObject var store: UsageStore
    @ObservedObject var settings: SettingsStore
    let onSettings: () -> Void
    let onAbout: () -> Void
    let onQuit: () -> Void

    private var visibleCards: [LimitDisplayState] {
        guard !store.state.hasError else { return [] }
        var cards: [LimitDisplayState] = []
        if settings.showFiveHour, let fiveHour = store.snapshot.fiveHour { cards.append(fiveHour) }
        if settings.showWeekly, let weekly = store.snapshot.weekly { cards.append(weekly) }
        return cards
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Limitly")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                Spacer()
                Menu {
                    Button("설정", action: onSettings)
                    Button("정보", action: onAbout)
                    Divider()
                    Button("종료", action: onQuit)
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 28, height: 28)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .help("메뉴")
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 12)

            if visibleCards.isEmpty {
                EmptyStateView(state: store.state, onRefresh: store.refresh)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HStack(spacing: 24) {
                    ForEach(visibleCards, id: \.kind) { card in
                        UsageCardView(card: card)
                    }
                }
                .padding(.horizontal, 22)
                .frame(maxHeight: .infinity)
            }

            Divider()
                .padding(.horizontal, 14)

            HStack(spacing: 8) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 7, height: 7)
                Text(lastUpdatedText)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Spacer()
                Button(action: store.refresh) {
                    Image(systemName: "arrow.clockwise")
                        .rotationEffect(.degrees(store.isRefreshing ? 360 : 0))
                }
                .buttonStyle(.borderless)
                .disabled(store.isRefreshing)
                .help("새로고침")
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 11)
        }
        .frame(width: 350, height: 350)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var statusColor: Color {
        switch store.state {
        case .connected: return .green
        case .refreshing: return .orange
        case .needsLogin, .failed: return .red
        case .idle: return .secondary
        }
    }

    private var lastUpdatedText: String {
        if let errorMessage = store.state.errorMessage {
            return errorMessage
        }
        guard let date = store.snapshot.lastSuccessfulFetch else { return store.state.label }
        return "최근 조회 " + DashboardDateFormatter.string(from: date)
    }
}

private struct EmptyStateView: View {
    let state: UsageConnectionState
    let onRefresh: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
            Text(state.label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(state.hasError ? .red : .primary)
                .multilineTextAlignment(.center)
            if case .needsLogin = state {
                Text("공식 Codex 앱에 로그인한 뒤 다시 시도하세요.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Button("다시 시도", action: onRefresh)
                .buttonStyle(.bordered)
        }
        .padding(24)
    }

    private var iconName: String {
        switch state {
        case .needsLogin: return "person.crop.circle.badge.exclamationmark"
        case .failed: return "exclamationmark.triangle"
        default: return "gauge.with.dots.needle.67percent"
        }
    }
}

private struct UsageCardView: View {
    let card: LimitDisplayState

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            VStack(spacing: 8) {
                Text(card.kind.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                RingGauge(progress: card.remainingPercent.map { $0 / 100 })
                    .frame(width: 108, height: 108)
                    .overlay {
                        VStack(spacing: 1) {
                            if let remaining = card.remainingPercent {
                                Text("\(Int(remaining.rounded()))%")
                                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                                Text("남음")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("—")
                                    .font(.system(size: 24, weight: .medium))
                            }
                        }
                    }
                if let resetDate = card.resetsAt {
                    Text(RemainingTimeFormatter.string(until: resetDate, now: context.date))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                } else {
                    Text("초기화 시간 —")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct RingGauge: View {
    let progress: Double?

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.22), lineWidth: 9)
            if let progress {
                Circle()
                    .trim(from: 0, to: CGFloat(min(1, max(0, progress))))
                    .stroke(
                        AngularGradient(
                            colors: [
                                Color(red: 0.06, green: 0.72, blue: 1.0),
                                Color(red: 0.08, green: 0.90, blue: 0.84),
                                Color(red: 0.06, green: 0.72, blue: 1.0)
                            ],
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 9, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
            }
        }
    }
}

struct SettingsView: View {
    @ObservedObject var settings: SettingsStore

    var body: some View {
        TabView {
            Form {
                Toggle("로그인 시 자동 실행", isOn: $settings.launchAtLogin)
                Picker("사용량 확인 주기", selection: $settings.refreshInterval) {
                    ForEach(RefreshInterval.allCases) { interval in
                        Text(interval.label).tag(interval)
                    }
                }
            }
            .formStyle(.grouped)
            .tabItem { Label("일반", systemImage: "gearshape") }

            Form {
                Toggle("메뉴바에 Limitly 표시", isOn: $settings.showMenuBar)
                Picker("표시 방식", selection: $settings.menuBarDisplayMode) {
                    ForEach(MenuBarDisplayMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                Toggle("5시간 한도", isOn: $settings.showFiveHour)
                Toggle("주간 한도", isOn: $settings.showWeekly)
            }
            .formStyle(.grouped)
            .tabItem { Label("메뉴바", systemImage: "menubar.rectangle") }
        }
        .padding(14)
        .frame(width: 520, height: 300)
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 12) {
            AppIconView()
                .frame(width: 86, height: 86)
            Text("Limitly")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
            Text("Version 1.0.0")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .frame(width: 320, height: 250)
        .padding()
    }
}

private struct AppIconView: View {
    var body: some View {
        Group {
            if let image = bundledIcon {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                BrandMarkFallback()
            }
        }
        .accessibilityLabel("Limitly 아이콘")
    }

    private var bundledIcon: NSImage? {
        if let url = Bundle.main.url(forResource: "LimitlyIcon", withExtension: "png"),
           let image = NSImage(contentsOf: url) {
            return image
        }
        return nil
    }
}

private struct BrandMarkFallback: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(red: 0.075, green: 0.102, blue: 0.169))
            Circle()
                .trim(from: 0.08, to: 0.86)
                .stroke(
                    Color(red: 0.965, green: 0.973, blue: 0.988),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .padding(18)
            Circle()
                .fill(Color(red: 0.04, green: 0.518, blue: 1.0))
                .frame(width: 17, height: 17)
                .offset(x: 23, y: -23)
        }
    }
}
