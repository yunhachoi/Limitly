# Limitly 구현 설계

## 목적

Limitly는 macOS 메뉴바에서 현재 로그인한 Codex 계정의 사용 한도를 빠르게 보여주는 arm64 전용 메뉴바 앱이다. 사용자는 GitHub Releases에서 DMG를 내려받아 `Limitly.app`을 설치하고, 별도의 Limitly 계정이나 API 키를 만들지 않는다.

## 확정된 요구사항

- macOS 13.0 이상
- Apple Silicon arm64 전용
- 앱 식별자 `local.limitly.usage-menubar`
- 버전 `1.0.0`
- 메뉴바에서 목업 기준 링+점 아이콘 또는 잔여 수치·초기화 시간 표시
- 대시보드 논리 크기 350×350
- 5시간 한도와 주간 한도의 잔여 비율·게이지·초기화까지의 시간
- 마지막 성공 조회 시각과 수동 새로고침
- 햄버거 메뉴: 설정·정보·종료, 자동 메뉴 화살표는 표시하지 않음
- 설정: 로그인 시 자동 실행, 조회 간격 30초·1분·5분(기본 1분), 메뉴바 표시, 아이콘/내용, 5시간·주간 카드 표시
- `Limitly.ico`를 원본 아이콘으로 사용하고 macOS용 `.icns`/PNG를 생성
- GitHub Releases의 `Limitly-<version>.dmg`만 공식 배포
- Windows 및 x86_64/Universal 산출물은 범위에서 제외

## 아키텍처

### LimitlyCore

SwiftPM 라이브러리 타깃으로 다음을 담당한다.

- `RateLimitWindow`, `RateLimitsSnapshot` 등 Codable 응답 모델
- `rateLimits`와 `rateLimitsByLimitId`의 호환 디코딩
- `windowDurationMins`와 식별자를 이용한 5시간·주간 선택
- 사용률을 0~100 사이로 제한한 잔여율 계산
- Unix 초 단위 `resetsAt`의 남은 시간 포맷
- JSON-RPC 요청 ID와 응답 매칭에 필요한 프로토콜 타입
- 연결 오류와 불완전한 응답을 UI가 처리할 수 있는 도메인 오류

### LimitlyApp

SwiftPM 실행 타깃으로 AppKit과 SwiftUI를 함께 사용한다.

- `AppDelegate`: 앱 수명주기, 메뉴바 상태, 팝오버, 설정/정보 창을 조정
- `NSStatusItem`: 메뉴바 링+점 아이콘 또는 잔여 수치·초기화 시간 표시
- `NSPopover`: 목업 기준 350×350 대시보드 표시
- SwiftUI `DashboardView`, `UsageCardView`, `SettingsView`, `AboutView`
- `UsageStore`: 단일 상태 원천, 조회 주기·마지막 성공 시각·오류 상태 관리
- `UserDefaults`/`@AppStorage`: 사용자 설정 저장
- `SMAppService`: 시작 시 실행 설정

AppKit bridge는 메뉴바·팝오버·일반 창 제어만 맡고, 사용량 상태와 계산은 `LimitlyCore`와 `UsageStore`에서만 관리한다.

## Codex 연결

Limitly는 중앙 서버를 두지 않는다. 각 사용자의 Mac에서 공식 Codex 실행 환경의 로컬 app-server를 사용한다.

1. 설치된 Codex 실행 파일을 알려진 고정 경로로 가정하지 않고 검색한다.
2. 현재 버전에서 지원하는 로컬 transport(기본 stdio 또는 검증된 Unix socket)를 선택한다.
3. 연결마다 `initialize` 요청과 `initialized` 알림을 먼저 보낸다.
4. `account/read`로 인증 상태를 확인한다.
5. `account/rateLimits/read`를 요청한다.
6. 응답에서 Codex 한도 버킷과 `usedPercent`, `windowDurationMins`, `resetsAt`을 선택해 UI 상태로 변환한다.

Limitly는 API 키·비밀번호·쿠키·토큰을 수집하거나 자체 저장하지 않는다. DMG에도 계정 정보와 개인 설정을 포함하지 않는다. 현재 설치된 Codex의 데스크톱 로그인 상태와 외부 app-server 프로세스의 인증 컨텍스트가 공유되는지는 통합 probe에서 확인한다. 공유되지 않으면 공식 Codex 로그인 흐름을 여는 복구 경로를 사용하고, 사설 인증 파일을 읽는 방식은 사용하지 않는다.

## UI 설계

- 목업의 어두운 카드·원형 게이지 구조를 유지하되 시스템 색상과 접근성 대비를 지원한다.
- 대시보드 상단에는 `Limitly` 제목과 메뉴 버튼을 둔다.
- 5시간·주간 카드는 좌우로 배치하고 카드 표시 설정에 따라 하나 또는 둘을 보여준다.
- 유효한 값은 정수 잔여 퍼센트로 표시하고 게이지는 원래 계산값을 사용한다.
- 주간 초기화까지 24시간 초과는 `N일 N시간 N분`, 24시간 이하는 `N시간 N분`으로 표시한다.
- 값이 없거나 검증되지 않으면 `—`로 표시한다. 초기화 시각이 지나도 새 응답 없이 100%로 바꾸지 않는다.
- 연결 실패는 마지막 성공 데이터와 분리해 상태 문구·재시도 버튼으로 표시한다.
- 정보 창에는 `.ico`에서 변환한 브랜드 아이콘, 앱 이름, 버전을 표시한다.

## 빌드·배포

- SwiftPM으로 arm64 macOS 13 타깃을 빌드한다.
- `script/build_and_run.sh`가 `.app` 번들을 staging하고 `/usr/bin/open -n`으로 실행한다.
- `scripts/package-dmg.sh`가 아이콘 변환, arm64 앱 번들 확인, `hdiutil create`, `hdiutil verify`를 수행한다.
- 공개 파일은 `Limitly-<version>.dmg` 하나이며 DMG 안에는 앱과 `/Applications` 별칭만 둔다.
- Developer ID 서명·hardened runtime·공증은 자격이 제공되는 배포 단계에서 적용한다.

## 검증 전략

- 계산·시간 포맷·응답 선택·JSONL framing 테스트를 먼저 실패 상태로 작성한다.
- fixture 응답으로 5시간·주간·누락·오류 사례를 검증한다.
- 실제 Mac에서는 연결 probe와 앱 실행을 별도로 확인한다.
- 앱 번들, `Info.plist`, arm64 Mach-O, DMG 무결성, 서명 상태를 스크립트로 확인한다.
