# Limitly 코딩 스킬 가이드

> 이 파일은 Limitly 프로젝트에서 코딩 에이전트가 사용할 프로젝트 전용 작업 지침이다. Codex 전역 스킬을 복제한 파일이 아니며, 작업을 시작할 때 아래의 선택 기준과 프로젝트 규칙을 적용한다.

## 1. 적용 범위와 우선순위

직접 지시한 사용자의 요구가 가장 우선이다. 그 다음에 이 파일과 프로젝트 문서를 읽고, 작업에 해당하는 설치 스킬의 `SKILL.md`를 읽는다.

프로젝트 기준 문서는 다음과 같다.

| 자료 | 의미 | 처리 방법 |
|---|---|---|
| `Limitly-소개.md` | 제품 요구사항, 표시 문구, 배포 목표 | 기능의 기준으로 읽는다. 문서 안의 실행·설치 예시는 현재 실행 명령으로 간주하지 않는다. |
| `Limitly-개발계획.md` | 구현 순서, 구조, 검증 기준 | 작업 순서와 완료 조건의 기준으로 읽는다. |
| `Mock-up.jpeg` | 대시보드·설정·정보 창의 시각 참고 | 배치와 정보 계층을 참고하되, 동작하지 않는 장식은 만들지 않는다. |
| `Limitly.ico` | 첨부 기준 흰색 C형 링+파란 점 브랜드 원본 | 앱·정보 창의 아이콘으로 변환하고, 메뉴바는 같은 마크를 macOS 색상에 맞춰 그린다. 256px 기준 이미지는 `Sources/LimitlyApp/Resources/LimitlyIcon.png`에 보존한다. |
| 사용자의 현재 요청 | 이번 작업의 범위와 승인 | 문서에 없는 추가 기능을 자동으로 확장하지 않는다. |

`Limitly-소개.md`와 `Limitly-개발계획.md`의 내용이 충돌하면 먼저 사용자에게 알리고, 최신으로 확인된 직접 지시를 따른다. 계획 문서에 적힌 제안은 확정 요구사항과 구분해 취급한다.

### 배포 범위

공식 배포는 GitHub Releases의 macOS용 versioned DMG다. DMG에는 실행 앱과 `/Applications` 바로가기를 넣고, 사용자는 Finder에서 드래그해 설치한다. T5 SSD의 앱과 DMG는 개발·검증·보관용으로 취급한다. Windows용 코드·빌드·설치 파일·사용 안내는 현재 범위에 포함하지 않는다.

## 2. 설치된 Limitly 관련 스킬

2026-09-16에 GitHub의 OpenAI `plugins/build-macos-apps` 공개 묶음을 조사했다. Limitly의 macOS SwiftUI/AppKit 개발에 필요한 아래 스킬을 Git sparse-checkout 방식으로 설치했다. 설치 경로는 `/Users/user/.codex/skills/<skill-name>/SKILL.md`다.

| 스킬 | 사용할 때 | Limitly 적용 |
|---|---|---|
| `build-run-debug` | 앱을 빌드·실행하거나 시작·런타임 오류를 조사할 때 | 프로젝트의 기본 개발 루프를 `script/build_and_run.sh` 하나로 유지한다. GUI SwiftPM 앱은 raw executable이 아니라 `.app` 번들로 실행한다. |
| `swiftpm-macos` | `Package.swift`가 주 진입점일 때 | `swift build`, `swift test`를 사용하고 executable·library·test product를 먼저 확인한다. |
| `swiftui-patterns` | SwiftUI scene, 메뉴, 설정, 화면 구조, 상태 소유권을 정할 때 | 메뉴바 앱·팝오버·설정 창의 역할을 나누고 `@AppStorage`·명시적 상태 전달을 우선한다. |
| `appkit-interop` | SwiftUI만으로 `NSStatusItem`, `NSPopover`, `NSWindow`, responder chain 등을 처리하기 어려울 때 | AppKit 브리지를 작은 경계로 두고 SwiftUI를 상태의 원천으로 유지한다. |
| `window-management` | 창 크기·드래그 영역·복원·titlebar를 조정할 때 | macOS 15+ 전용 API는 배포 목표 macOS 13을 고려해 availability guard 또는 AppKit 대체 경로를 둔다. |
| `test-triage` | SwiftPM/Xcode 테스트가 실패했을 때 | 가장 작은 테스트 범위부터 실행하고 컴파일·assertion·crash·환경 문제를 구분한다. |
| `signing-entitlements` | 서명·sandbox·hardened runtime·Gatekeeper 문제가 있을 때 | 실제 `.app` 또는 binary를 검사한 증거를 바탕으로만 수정한다. |
| `packaging-notarization` | GitHub Release용 DMG·서명 앱·공증 준비를 할 때 | 로컬 디버그와 배포 검증을 분리하고 DMG·번들·중첩 코드·entitlement를 확인한다. |
| `telemetry` | 메뉴바 동작·조회·복구 경로를 로그로 확인할 때 | `OSLog.Logger`를 사용하고 token·비밀번호·개인정보·원시 응답을 로그에 남기지 않는다. |

## 3. 기존 설치 스킬 중 함께 사용할 것

| 스킬 | 사용 시점 | 적용 규칙 |
|---|---|---|
| `using-superpowers` | 모든 작업 시작 시 | 해당 작업에 맞는 스킬을 먼저 찾고 읽는다. |
| `brainstorming` | 새 기능·화면·동작·구조를 만들거나 변경할 때 | 범위를 먼저 분류하고, 구현 전에 설계 의도를 사용자에게 제시한다. |
| `writing-plans` | 여러 단계의 구현 계획이 필요할 때 | 파일·인터페이스·테스트·완료 조건이 있는 실행 계획을 만든다. |
| `ponytail` | 모든 코딩 작업 | 표준 라이브러리와 macOS 기본 API를 먼저 검토하고, 불필요한 의존성·추상화·파일을 만들지 않는다. |
| `test-driven-development` | production code를 추가·변경하기 전 | 실패하는 테스트를 먼저 보고 최소 구현을 작성한다. |
| `systematic-debugging` | 버그·예상 밖 동작·테스트 실패를 만났을 때 | 재현, 원인 추적, 가설 검증 순서로 진행하며 증상만 가리지 않는다. |
| `accessibility` | 화면·컨트롤·키보드 동작을 만들거나 검토할 때 | VoiceOver 이름, 키보드 조작, 대비, Dynamic Type과 macOS 표준 동작을 확인한다. |
| `best-practices` | 보안·호환성·품질 검토를 요청받았을 때 | 요청 범위에 맞는 점검만 하고 관련 없는 전면 리팩터링은 하지 않는다. |
| `openai-docs` | Codex app-server 연결·프로토콜·사용량 응답을 다룰 때 | 공식 OpenAI 문서와 설치된 Codex 도움말을 확인한다. `account/rateLimits/read`와 로그인 세션 공유를 추측하지 않는다. |
| `verification-before-completion` | 완료·수정·통과를 주장하기 직전 | 실행한 명령과 실제 출력으로 주장을 증명한다. |
| `requesting-code-review` | 주요 기능 완료 또는 병합 전 | 요구사항·회귀·보안·사용성 관점의 검토를 요청한다. |
| `receiving-code-review` | 리뷰 의견을 받은 뒤 | 의견을 그대로 적용하지 말고 재현 가능한 기술 근거를 확인한다. |
| `using-git-worktrees` | 격리된 브랜치가 필요할 때 | 기존 작업을 덮어쓰지 않는 별도 작업 공간을 먼저 준비한다. |

### ECC / agent-skills 확인

프로젝트에 정확히 이름이 `ECC` 또는 `agent-skills`인 설치 묶음은 없었다. 대신 GitHub의 공식 `affaan-m/ECC` 저장소에서 이 macOS Swift 작업에 직접 필요한 두 스킬을 설치해 사용한다.

| 설치 스킬 | 출처·경로 | 이번 작업에서 적용한 내용 |
|---|---|---|
| `tdd-workflow` | `affaan-m/ECC/.agents/skills/tdd-workflow` → `/Users/user/.codex/skills/tdd-workflow` | 메뉴바 초기화 시간과 날짜 포맷 테스트를 production code보다 먼저 작성하고 RED→GREEN 순서를 확인했다. |
| `verification-loop` | `affaan-m/ECC/.agents/skills/verification-loop` → `/Users/user/.codex/skills/verification-loop` | core check, release build, 번들·DMG·아이콘 검증을 완료 보고 전에 순서대로 실행한다. |

전체 ECC 묶음은 설치하지 않고 현재 작업에 필요한 범위만 설치한다. 웹 검색이나 외부 설치가 필요한 새 스킬은 먼저 출처·범위·필요성을 확인한 뒤 이 표에 기록한다.

### UI 및 Agent Skills 확인·설치 기록 (2026-09-17)

#### 설치 상태 점검

- /Users/user/.codex/skills/에는 다음 네이티브 macOS UI 스킬이 이미 설치되어 있다.
  - swiftui-patterns: SwiftUI 화면·메뉴·설정·상태 소유권과 데스크톱 패턴
  - appkit-interop: NSStatusItem, NSPopover, NSWindow 같은 AppKit 경계
  - window-management: macOS 창 크기·titlebar·배치·복원·활성화 정책
  - accessibility: VoiceOver 이름·키보드 경로·대비·접근성 검사
- skill-ui-cli와 skill-lookup도 설치되어 있다. skill-ui 명령은 실행되지만 현재 GitHub 저장소 설정과 인증 토큰이 없어 개인 Skill UI 저장소 목록을 읽는 용도로는 사용할 수 없다.
- /Users/user/.agents/skills/에는 playwright-cli가 설치되어 있다. Codex에서 실제로 읽고 적용할 전역 스킬은 /Users/user/.codex/skills/를 기준으로 한다.
- 정확한 이름의 agent-skills 단일 폴더는 발견되지 않았다. GitHub의 anthropics/skills는 Agent Skills open format으로 작성된 여러 분야의 공개 모음이고, affaan-m/ECC는 개발·검증·에이전트 작업 스킬 모음이다. 두 저장소 전체를 프로젝트에 복사하지 않고 Limitly에 직접 맞는 번들만 선택한다.
- agent-skills 저장소 자체는 addyosmani/agent-skills로 확인했으며, 전체 24개 묶음 대신 작업 단계 선택용 메타 스킬 `using-agent-skills` v0.6.9를 `/Users/user/.codex/skills/using-agent-skills/`에 설치했다.

#### 추가 설치한 네이티브 UI Agent Skill

| 스킬 | 출처·설치 경로 | 사용할 때 |
|---|---|---|
| swiftui-expert-skill v5.0.0 | AvdLee/SwiftUI-Agent-Skill · /Users/user/.codex/skills/swiftui-expert-skill/ | SwiftUI 상태 관리·@Observable·뷰 합성·레이아웃·성능·macOS scene/window·툴바·접근성·API 마이그레이션을 검토하거나 수정할 때 |
| using-agent-skills v0.6.9 | addyosmani/agent-skills · /Users/user/.codex/skills/using-agent-skills/ | 새 작업이나 세션에서 요구사항 정리→계획→구현→테스트→리뷰→배포 중 필요한 Agent Skill 워크플로우를 고를 때 |

이 번들은 SKILL.md, references/ 32개, agents/openai.yaml, macOS/SwiftUI 참고 문서와 trace 분석 스크립트를 포함한 전체 형태로 설치했다. 설치 후 /Users/user/.codex/skills/swiftui-expert-skill/SKILL.md를 다시 읽어 frontmatter와 번들 구조를 확인했다. AvdLee/SwiftUI-Agent-Skill을 선택한 이유는 Codex용 .codex-plugin manifest와 macos-scenes, macos-window-styling, macos-views, accessibility-patterns 등 Limitly의 실제 UI 범위를 포함하기 때문이다. 동일 목적의 twostraws/SwiftUI-Agent-Skill은 후보로 확인했지만 중복 설치하지 않는다.

#### UI 작업별 선택 순서

| 작업 | 먼저 읽을 스킬 | 함께 읽을 참고 |
|---|---|---|
| SwiftUI 상태·뷰 구조·레이아웃·성능 | swiftui-expert-skill, swiftui-patterns | state-management.md, view-structure.md, layout-best-practices.md, performance-patterns.md |
| 메뉴바·팝오버·설정/정보 창 | appkit-interop, window-management, swiftui-expert-skill | macos-scenes.md, macos-window-styling.md, macos-views.md, 현재 AppKit bridge |
| VoiceOver·키보드·대비·동적 글자 | accessibility, swiftui-expert-skill | accessibility-patterns.md |
| 목업과 실제 UI 비교 | swiftui-expert-skill, accessibility | layout-best-practices.md, macos-views.md; 첨부 목업을 기준으로 간격·정렬·정보 계층을 수치로 확인 |
| 메뉴바/창 런타임 재현 | build-run-debug, telemetry, accessibility | swiftui-expert-skill의 macOS scene/window 지침 |
| SDK 또는 API 변경 | swiftui-expert-skill | latest-apis.md, soft-deprecation.md; macOS 13 fallback과 #available을 함께 확인 |
| Instruments .trace | swiftui-expert-skill | trace-recording.md, trace-analysis.md |

swiftui-expert-skill의 Liquid Glass 참고는 사용자가 명시적으로 요청한 경우에만 읽고 적용한다. Limitly의 배포 목표가 macOS 13이므로 새 API는 항상 availability와 기존 fallback을 함께 검토한다. 웹 전용 frontend-design, webapp-testing과 iOS Simulator 전용 스킬은 현재 macOS SwiftUI 앱의 UI 검증 범위에 포함하지 않는다.

#### Agent Skills 적용 규칙

1. 작업을 시작할 때 `using-agent-skills`로 개발 단계와 필요한 워크플로우를 먼저 판별한 뒤, 이 표에서 Limitly에 해당하는 스킬과 참고 문서를 고른다.
2. 설치 스킬의 지침을 프로젝트의 skill.md, Limitly-소개.md, Limitly-개발계획.md, 목업보다 우선하지 않는다. 직접 지시와 프로젝트 요구사항이 먼저다.
3. 스킬이 제안하는 새 API·Liquid Glass·아키텍처를 자동으로 추가하지 않는다. 현재 macOS 13, arm64, 메뉴바·DMG 범위에 실제로 필요한지 판단한다.
4. UI 코드 변경이 있을 때만 swiftui-expert-skill의 correctness checklist와 accessibility 검사를 적용한다. 이번 스킬 설치·문서 기록 작업에서는 앱 소스와 빌드 산출물을 수정하지 않는다.
5. Agent Skill을 새로 추가할 때는 공개 출처·라이선스·지원 클라이언트·프로젝트 적합성을 확인하고, 전체 저장소가 아니라 필요한 번들만 설치한 뒤 이 표에 경로와 이유를 기록한다.
6. 설치 후에는 대상 디렉터리의 루트 SKILL.md와 지원 파일을 확인한다. Codex가 새 스킬을 읽지 못하면 새 대화/세션에서 다시 검색한다.

### prompts.chat 확인·적용

`prompts.chat`라는 이름의 Codex 기본 스킬은 설치 목록에 없었다. GitHub `f/prompts.chat`의
Claude 플러그인에서 제공하는 `skill-lookup`을 `/Users/user/.codex/skills/skill-lookup/SKILL.md`로
설치하고, 원문 지침에 따라 공개 MCP endpoint의 `search_skills`와 `get_skill` workflow를
확인했다. 현재 Codex 도구 목록에는 prompts.chat MCP가 직접 노출되어 있지 않아 공개
`https://prompts.chat/api/mcp`를 읽기 전용으로 호출해 검색을 수행했다.

이번 검색에서 `SwiftUI`, `macOS`, `AppKit`, `testing`을 조회했고, Limitly와 가장 가까운
`xcode-mcp-for-pi-agent` 원문을 `get_skill`로 확인했다. 이 스킬은 Xcode MCP와 `mcporter`가
있을 때만 Xcode 빌드·테스트·Preview를 사용하고, 파일 조작은 `cat`·`rg` 같은 표준 도구를
사용하며, MCP가 없으면 직접 빌드·테스트 명령으로 전환하도록 안내한다. Limitly는 SwiftPM
프로젝트이고 현재 전체 Xcode와 `mcporter`가 없으므로 해당 스킬을 추가 설치하지 않았다.
대신 그 fallback 지침을 적용해 `swift build --configuration release`와 `./scripts/test.sh`를
사용했고, arm64 앱·DMG 검증까지 통과했다. 이 작업에서 prompts.chat skill-lookup은 스킬
검색·원문 확인에 실제 사용되었으며, 앱 런타임에 prompts.chat 또는 외부 MCP를 포함하지 않는다.

`playwright`와 iOS simulator 전용 스킬은 이 macOS 메뉴바 앱의 기본 검증 도구로 사용하지 않는다. 웹 화면이나 모바일 시뮬레이터가 별도 범위로 추가된 경우에만 다시 판단한다.

## 4. 작업별 스킬 선택 순서

작업이 시작되면 다음 순서로 필요한 스킬만 읽는다.

1. 프로젝트 문서와 현재 파일 구조를 읽는다.
2. 새 기능·구조 변경이면 `brainstorming`을 적용한다.
3. 단계가 여러 개면 `writing-plans`를 적용한다.
4. 구현 전에는 `ponytail`과 `test-driven-development`를 적용한다.
5. SwiftPM 프로젝트면 `swiftpm-macos`, SwiftUI 화면이면 `swiftui-patterns`를 적용한다.
6. `NSStatusItem`·`NSPopover`·`NSWindow`처럼 macOS imperative API가 필요할 때만 `appkit-interop` 또는 `window-management`를 추가한다.
7. 빌드·실행은 `build-run-debug`, 테스트 실패 분류는 `test-triage`, 원인 불명 오류는 `systematic-debugging`을 적용한다.
8. 로그가 필요한 경우 `telemetry`, 사용자 조작을 확인할 때 `accessibility`를 적용한다.
9. 앱을 배포할 때만 `signing-entitlements`와 `packaging-notarization`을 적용한다.
10. 완료를 보고하기 전 `verification-before-completion`으로 명령과 출력을 확인한다.

한 작업에 모든 스킬을 무조건 읽지 않는다. 해당 기술·오류·산출물이 실제로 존재할 때만 읽어 필요한 지침을 적용한다.

## 5. Limitly 구현 규칙

### 5.1 구조와 의존성

- SwiftUI는 화면과 값 상태를 담당하고, AppKit은 메뉴바·팝오버·창처럼 macOS 전용 동작만 담당한다.
- 메뉴바와 대시보드는 하나의 사용량 상태를 공유한다. 화면마다 Codex를 따로 조회하지 않는다.
- `App`, `Views`, `Models`, `Stores`, `Services`, `Support` 역할을 섞지 않는다. 한 파일에 앱 진입점·모든 뷰·네트워크·포맷터를 넣지 않는다.
- Swift 표준 라이브러리와 Foundation·SwiftUI·AppKit·ServiceManagement를 먼저 사용한다. 새 패키지는 실제 부족한 기능과 유지 비용을 기록한 뒤 추가한다.
- 개발 실행 진입점은 `script/build_and_run.sh`로 통일한다. 패키징용 스크립트와 앱 소스 안에 실행 로직을 복사하지 않는다.
- SwiftUI/AppKit GUI는 raw executable로 실행하지 않고 최소 `Info.plist`를 포함한 `.app` 번들로 실행한다.
- macOS 13을 배포 목표로 삼는다. macOS 15 이상 API를 사용할 경우 availability를 검사하고 macOS 13 경로를 유지한다.

### 5.2 Codex 연결과 사용량 데이터

- 별도 API 키, 비밀번호 입력, 로그인 화면, 토큰 복사·저장을 추가하지 않는다.
- 공식 Codex 앱의 로컬 app-server 연결과 `account/rateLimits/read`를 먼저 실제 환경에서 검증한다.
- 배포 앱은 각 사용자의 Mac에서 해당 사용자의 Codex 인증 컨텍스트로만 조회한다. 중앙 서버·공용 계정·공용 토큰을 만들지 않으며, DMG에 인증 정보를 넣지 않는다.
- 연결마다 `initialize` → `initialized` 이후 요청을 보낸다. 요청 ID로 응답을 구분하고 알림과 오류 응답을 섞지 않는다.
- `rateLimitsByLimitId`가 있으면 Codex에 맞는 묶음을 우선 검토하고, 구형 응답의 `rateLimits`를 대체 경로로 사용한다.
- `windowDurationMins`와 식별자를 함께 확인해 5시간·주간을 선택한다. `primary`·`secondary`라는 위치만으로 한도를 단정하지 않는다.
- 남은 비율은 `100 - usedPercent`를 0부터 100 사이로 제한한다. 값이 없거나 해석되지 않으면 `—`로 표시한다.
- 초기화 시각이 지나도 새 조회 없이 잔여량을 100%로 바꾸지 않는다. 마지막 성공 데이터와 오류 상태를 별도로 유지한다.
- 로그·오류·테스트 fixture에 인증 토큰, 쿠키, 비밀번호, 원시 개인 계정 응답을 넣지 않는다.

### 5.3 화면과 접근성

- 대시보드는 논리 크기 350×350에서 5시간·주간 카드를 좌우로 표시한다.
- 게이지·큰 비율·초기화까지의 시간·최근 조회 시각·연결 상태를 같은 상태 모델에서 렌더링한다.
- 메뉴바에는 아이콘 모드와 수치 모드를 제공하고, 수치는 `5h 58% (3시간 43분)  W 77% (6일 17시간 41분)`처럼 잔여 비율과 초기화까지 남은 시간을 짧고 분명하게 표시한다. 툴팁·접근성 이름에는 값이 5시간인지 주간인지 명시한다.
- 메뉴바 항목을 숨겨도 앱을 다시 열었을 때 설정을 통해 복구할 수 있어야 한다. 두 번째 앱 인스턴스를 만들지 않는다.
- 표준 macOS 메뉴·새로고침·설정·정보·종료 아이콘과 키보드 경로를 사용한다.
- 밝은 모드·어두운 모드에서 시스템 색상·재료·semantic foreground를 우선하고, 게이지와 글자의 대비를 확인한다.
- 연결 중·로그인 필요·연결 실패·정상 조회를 구분한다. 실패를 정상적인 0%·100% 상태로 보이지 않는다.

### 5.4 설정·자동 실행·창

- 조회 주기는 30초·1분·5분이며 기본값은 1분이다. 새 설치의 메뉴바 표시 기본값은 수치(`content`), 로그인 시 자동 실행 기본값은 켬이며, 기존 UserDefaults 값은 보존한다. 설정 변경은 저장하고 기존 타이머를 교체한다.
- 자동 실행은 `SMAppService` 상태와 실제 OS 등록 결과를 함께 확인한다. 수동 plist와 현대 API를 중복 등록하지 않는다.
- 설정과 정보는 일반 창으로, 대시보드는 메뉴바에 붙는 팝오버로 구분한다.
- 창 동작을 위해 AppKit을 사용하더라도 bridge가 데이터의 두 번째 원천이 되지 않게 한다.
- 팝오버 바깥 클릭·Escape 닫기, 메뉴 접근, 설정 복귀, 절전 후 재조회와 Codex 재시작 후 복구를 확인한다.

## 6. 테스트 규칙

production code보다 먼저 다음과 같은 실패 테스트를 만든다.

| 영역 | 먼저 검증할 동작 |
|---|---|
| 계산 | 사용 비율→남은 비율, 0·100 초과 값 제한, 누락 값 |
| 시간 | 24시간 경계, 일·시간·분 표기, 1분 미만, 초기화 시각 경과 |
| 응답 | `rateLimitsByLimitId`·구형 `rateLimits`, 5시간·주간 선택, 일부 누락 |
| 프로토콜 | initialize 순서, 요청 ID, 분할 메시지, 서버 오류, 제한 시간 |
| 상태 | 마지막 성공 시각 유지, 중복 요청 방지, 실패 후 재시도 |
| 설정 | 기본값, 저장·재실행, 주기 변경, 한도·메뉴바 표시 변경 |

테스트는 실제 동작과 계산 결과를 검증하고, 단순히 mock 호출 횟수만 검증하지 않는다. 화면과 프로세스 연결은 순수 계산 테스트와 분리해 작은 범위부터 실행한다.

현재 Xcode 전체 도구가 확인되지 않은 환경에서는 가능한 범위에서 SwiftPM을 우선 사용한다.

```sh
cd '/Volumes/T5 SSD/Limitly'
swift build --disable-sandbox --configuration release
```

`scripts/test.sh`가 XCTest 모듈을 자동 감지한다. 전체 Xcode가 있으면 `swift test`를 실행하고, Command Line Tools만 있으면 `scripts/main.swift`의 동일한 핵심 계산·프로토콜 check를 실행한다. XCTest 파일을 직접 실행하려면 전체 Xcode를 설치하고 `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`를 먼저 수행한 뒤, 프로젝트가 사용자 캐시를 쓰지 않도록 `CLANG_MODULE_CACHE_PATH`와 `SWIFT_MODULECACHE_PATH`를 `/private/tmp` 아래로 지정한다.

구현 후 다음 개발 루프를 사용한다. 빌드 스크립트는 기본적으로 `/private/tmp/limitly-build-arm64`에 생성물을 두며 `LIMITLY_BUILD_PATH`로 변경할 수 있다.

```sh
./script/build_and_run.sh
LIMITLY_NO_LAUNCH=1 ./script/build_and_run.sh
./scripts/test.sh
./scripts/probe-codex.py
./scripts/verify.sh /private/tmp/limitly-build-arm64/Limitly.app
./scripts/package-dmg.sh
```

실패하면 먼저 `test-triage`로 범위를 줄이고, 원인이 불명확하거나 재현이 어려우면 `systematic-debugging`으로 전환한다.

## 7. 로그와 보안

- `OSLog.Logger`의 subsystem은 `local.limitly.usage-menubar`, category는 `Connection`, `Usage`, `MenuBar`, `Window`, `Settings`처럼 기능별로 나눈다.
- 로그에는 연결 시작·성공·실패·재시도·사용자 메뉴 동작 같은 경계만 남긴다. 전체 JSON 응답·계정 식별자·토큰·파일 경로의 민감한 부분을 출력하지 않는다.
- 로그 확인은 필요할 때 다음처럼 좁은 predicate를 사용한다.

```sh
log stream --style compact --predicate 'subsystem == "local.limitly.usage-menubar"'
```

- 프로토콜 오류와 표준 오류 출력을 분리한다. 연결 실패를 조용히 삼키지 않되, 사용자에게 필요한 복구 안내만 보여준다.
- 외부 입력이나 서버 응답을 화면에 표시하기 전에 타입·범위·누락 값을 검증한다.

## 8. 빌드·서명·배포

개발 실행과 배포 검증을 나눈다.

| 목적 | 적용 스킬 | 확인 내용 |
|---|---|---|
| 로컬 실행 | `build-run-debug`, `swiftpm-macos` | `.app` 생성, foreground 실행, process 존재, 런타임 오류 |
| 테스트 실패 | `test-triage`, `systematic-debugging` | 가장 작은 실패 범위, 원인 분류, 재현 명령 |
| 서명 문제 | `signing-entitlements` | identity, entitlements, nested code, hardened runtime, Gatekeeper |
| DMG·GitHub Releases | `packaging-notarization` | DMG 구조, 리소스, 실행 권한, 서명·공증 준비 상태 |
| 최종 보고 | `verification-before-completion` | 실행한 명령·출력·검증 환경·미검증 범위 |

공개 배포 산출물은 `Limitly-<version>.dmg`로 통일한다. `hdiutil create`로 writable 이미지를 만든 뒤 Finder 메타데이터 생성/닫기와 최종 700×400·128px·자유 정렬·가로 배치·100×100 점선 화살표 배경 저장을 두 단계로 수행하고, 충분한 저장 대기 후 `hdiutil convert`와 `hdiutil verify`를 실행한다. 앱 번들에는 `codesign`·`spctl` 검사를 적용한다. GitHub Release 업로드와 공증은 실제 저장소·개발자 계정 권한이 확인된 경우에만 수행한다. 서명·공증이 필요한 배포 요청이 있기 전에는 로컬 디버그에 배포용 절차를 강제하지 않는다. 자격증명이나 개인 키를 저장소에 넣지 않는다.

Windows용 산출물은 만들거나 배포하지 않는다. Apple Silicon arm64 전용 macOS 빌드와 macOS 13 호환성만 검증한다. Intel x86_64 빌드·변환·검증은 하지 않는다.

## 9. 지금 설치하지 않은 스킬

GitHub의 같은 macOS 묶음에 `view-refactor`와 `liquid-glass`도 있지만 현재 Limitly에는 설치하지 않았다.

- `view-refactor`: 실제로 큰 SwiftUI 뷰가 생기고 구조 분해가 필요할 때 설치한다.
- `liquid-glass`: 사용자가 Liquid Glass를 명시하거나 목표 OS에 맞는 시각 효과를 선택할 때 설치한다. 현재 요구사항은 목업의 카드와 게이지이며, macOS 13 호환성이 먼저다.
- Windows, iOS simulator·App Store 배포 전용 스킬: Limitly의 macOS DMG 배포 범위에는 해당하지 않는다.

새 스킬이 필요해지면 먼저 공개 저장소·공식 문서·현재 설치 목록을 확인하고, 이름·범위·출처·설치 이유를 이 파일에 기록한 뒤 설치한다. 프로젝트에 실제로 필요한 기능을 해결하는 스킬만 추가한다.

## 10. 완료 보고 형식

작업을 마쳤다고 말하기 전에 다음을 기록한다.

1. 어떤 스킬을 읽고 적용했는지
2. 어떤 파일을 만들거나 수정했는지
3. 어떤 테스트·빌드·실행 명령을 실행했는지
4. 명령이 성공했는지와 핵심 출력
5. 실제 Codex 로그인 세션·macOS 버전·CPU에서 확인했는지
6. 아직 확인하지 못한 OS·CPU·서명·공증 범위

`swift build`가 통과한 것만으로 메뉴바 UI·Codex 세션 연결·설치 패키지가 완성됐다고 말하지 않는다. 각 주장은 해당 동작을 직접 확인한 증거가 있을 때만 완료로 표시한다.

## 11. 설치 기록과 출처

- 설치 출처: [OpenAI plugins — build-macos-apps](https://github.com/openai/plugins/tree/main/plugins/build-macos-apps)
- 설치한 스킬: `build-run-debug`, `swiftpm-macos`, `swiftui-patterns`, `window-management`, `appkit-interop`, `test-triage`, `signing-entitlements`, `packaging-notarization`, `telemetry`, `swiftui-expert-skill`, `using-agent-skills`
- ECC 확인·설치: 정확한 `ECC` 폴더는 없어 `affaan-m/ECC`의 `tdd-workflow`, `verification-loop`만 Git 방식으로 설치하고 코드 작업에 적용한다.
- agent-skills 확인·설치: `addyosmani/agent-skills` 전체를 복사하지 않고 Codex에서 사용할 메타 스킬 `using-agent-skills`만 Git 방식으로 설치했다. UI 구현에는 네이티브 `swiftui-expert-skill`과 기존 macOS UI 스킬을 우선한다.
- prompts.chat 확인·설치: 정확한 Codex 기본 스킬은 없어 `f/prompts.chat`의 `skill-lookup`을 설치했다. 공개 `search_skills`·`get_skill` 호출로 macOS 관련 스킬을 확인했고, MCP가 없는 SwiftPM 프로젝트에는 해당 스킬의 fallback 빌드·테스트 절차를 적용했다.
- 설치 위치: `/Users/user/.codex/skills/`
- 설치 방식: Python 다운로드 경로의 인증서 오류 후 설치 도구의 Git 방식으로 설치
- Codex 연결 참고: [Codex App Server 문서](https://learn.chatgpt.com/docs/app-server)

설치된 스킬의 실제 `SKILL.md`가 이 파일보다 최신이면 해당 스킬의 지침을 우선 읽고 적용한다. 이 파일은 Limitly의 제품 규칙과 선택 기준을 보완하는 프로젝트 전용 가이드다.
