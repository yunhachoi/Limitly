# Limitly 구현 계획

> 승인된 설계: `docs/superpowers/specs/2026-09-16-limitly-design.md`

## 1. 프로젝트 골격

- [x] SwiftPM `Package.swift`를 macOS 13 arm64 기준으로 만든다.
- [x] `LimitlyCore` 라이브러리와 `LimitlyApp` 실행 타깃을 만든다.
- [x] `.codex/environments/environment.toml`, `script/build_and_run.sh`를 추가한다.
- [x] 앱 식별자·버전·메뉴바 앱용 `Info.plist`를 추가한다.

## 2. TDD: 순수 모델·계산

- [x] 사용률에서 잔여율을 계산하는 실패 테스트를 작성한다.
- [x] 5시간(300분)·주간(10080분) 버킷 선택 실패 테스트를 작성한다.
- [x] 24시간 경계와 `N일 N시간 N분`/`N시간 N분` 포맷 실패 테스트를 작성한다.
- [x] 누락·null·범위 초과 응답 테스트를 작성한다.
- [x] 테스트를 통과시키는 `LimitlyCore` 구현을 추가한다.

## 3. TDD: app-server 프로토콜

- [x] JSON-RPC 요청·응답 모델과 요청 ID 매칭 실패 테스트를 작성한다.
- [x] JSONL 분할 수신, 서버 오류, 초기화 순서, 제한 시간 테스트를 작성한다.
- [x] `rateLimits`/`rateLimitsByLimitId` fixture를 추가한다.
- [x] Foundation `Process`·`Pipe` 기반 stdio transport를 구현한다.
- [x] 설치된 Codex 실행 파일 검색과 `account/read`/`account/rateLimits/read` probe를 구현한다.
- [x] 현재 환경에서 기존 로그인 컨텍스트 공유 여부를 검증하고 결과를 기록한다.

## 4. 앱 상태와 UI

- [x] `UsageStore`와 조회 주기·재시도·마지막 성공 시각 상태를 구현한다.
- [x] 목업 기준 대시보드와 카드·게이지·새로고침을 구현한다.
- [x] `NSStatusItem`/`NSPopover` AppKit bridge를 구현한다.
- [x] 설정 창과 정보 창을 구현한다.
- [x] `UserDefaults` 저장과 `SMAppService` 토글을 연결한다.
- [x] `.ico`에서 앱 리소스용 아이콘을 생성하고 정보 화면·메뉴바에 적용한다.

## 5. 빌드·실행·검증

- [x] arm64 `.app` staging 및 foreground 실행을 확인한다.
- [x] SwiftPM core check와 앱 실행·연결 probe를 확인한다. 전체 XCTest는 현재 호스트의 Xcode 부재로 별도 기록한다.
- [ ] 연결 실패·재연결·Codex 재시작·절전 복귀 상태를 장시간 확인한다.
- [x] `scripts/verify.sh`로 번들·식별자·최소 OS·arm64를 확인한다.

## 6. DMG 배포

- [x] `scripts/package-dmg.sh`로 `Limitly-1.0.0.dmg`를 만든다.
- [x] DMG에 앱과 `/Applications` 별칭만 포함되는지 확인한다.
- [x] `hdiutil verify`와 마운트·직접 실행·Codex probe를 확인한다.
- [ ] 서명·공증 자격이 있으면 Developer ID 절차를 적용하고 결과를 기록한다.
- [ ] GitHub Release 노트와 DMG 업로드 절차를 문서화한다.
