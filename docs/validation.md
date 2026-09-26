# Limitly 검증 기록 (공개용)

## 완료된 검증

- SwiftPM arm64 debug·release 빌드
- 경고를 오류로 처리한 release 빌드
- 잔여율·범위 제한·윈도우 선택·초기화 시간·날짜 포맷·JSONL·JSON-RPC core check
- 공식 Codex app-server 연결 probe
- Codex 앱 번들 내부 실행 파일 자동 탐색 및 디렉터리 오인 실행 회귀 검사
- 앱 번들 메타데이터·arm64 Mach-O·아이콘 리소스 확인
- `.ico`에서 PNG·ICNS 변환 확인
- ad hoc code signature 확인
- DMG 생성 및 `hdiutil verify` 확인
- DMG staging에 앱·Applications 별칭·볼륨 아이콘·설치 안내 화살표 포함 확인
- Finder 레이아웃의 700×400 창·128px 아이콘·가로 배치 확인
- 메뉴바 팝오버 토글과 외부 앱 활성화 시 닫힘 동작 확인
- 앱 중복 실행 방지·LaunchServices/Launchpad 애플리케이션 메타데이터 확인
- 새 설치 기본값(메뉴바 수치 표시·로그인 시 자동 실행 켬) 확인
- 대시보드 카드 간격·폰트 크기·초기화 시간 표시 확인

## 공개하지 않는 검증 정보

개인 Mac의 절대 경로, Codex 버전 문자열, 실제 계정 사용률, 인증 상태의 원시 응답, 사용자 이름과 작업 폴더는 공개 문서에 기록하지 않는다.

## 미검증 또는 추가 확인

- 전체 XCTest 실행은 Xcode가 설치된 환경에서 추가 확인한다.
- macOS 13 실기기에서 장시간 절전 복귀 동작을 추가 확인한다.
- Developer ID 서명·hardened runtime·공증·staple은 배포 계정과 인증서가 제공될 때 추가한다.
- 현재 DMG는 로컬 검증용 ad hoc 서명이다.
