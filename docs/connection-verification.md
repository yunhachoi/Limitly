# Codex 연결 검증 기록 (공개용)

## 검증 범위

- Apple Silicon arm64 빌드
- 공식 Codex 앱 번들 내부 실행 파일 자동 탐색
- `codex app-server --stdio` JSONL transport 연결
- `initialize`, `initialized`, `account/read`, `account/rateLimits/read` 흐름

개인 계정의 실제 사용량·이메일·인증 토큰·원시 응답은 공개 문서에 기록하지 않는다.

## 응답 해석

- 5시간 윈도우는 `windowDurationMins = 300`을 사용한다.
- 주간 윈도우는 `windowDurationMins = 10080`을 사용한다.
- 잔여율은 `100 - usedPercent`를 0부터 100 사이로 제한한다.
- 초기화 시각은 초 단위 Unix timestamp를 사용한다.

`usedPercent`는 Codex app-server가 반환하는 사용률이고, Limitly 화면의 `남음`과 메뉴바 퍼센트는 `remainingPercent`를 표시한다. 따라서 두 값의 합은 100이 된다.

Limitly는 공식 Codex 앱 번들을 기준으로 내부 실행 파일을 자동 탐색하며, 디렉터리를 실행 파일로 잘못 선택하지 않는다. Codex 업데이트로 번들 내부 하위 경로가 바뀌어도 같은 번들 안에서 실행 파일을 찾도록 구성되어 있다.

## 배포 시 사용자별 분리

DMG에는 계정 정보가 없다. 각 사용자의 Mac에서 Limitly가 해당 사용자 컨텍스트의 Codex app-server를 조회하므로 같은 DMG를 설치해도 계정별 rate limit 응답이 분리된다. 중앙 Limitly 서버나 공용 토큰은 사용하지 않는다.

## 제한 사항

공식 Codex 데스크톱 앱의 로그인 상태와 별도로 실행한 app-server 프로세스의 인증 컨텍스트 공유는 Codex 버전별로 확인해야 한다. 공유되지 않는 환경에서는 공식 Codex 로그인 흐름이 필요하며, 사설 인증 파일을 읽는 방식은 사용하지 않는다.
