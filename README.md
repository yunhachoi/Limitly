# Limitly

Limitly는 macOS 메뉴바에서 Codex 사용 한도를 확인하는 앱입니다. 로그인한 사용자의 5시간 한도와 주간 한도, 각 한도의 초기화까지 남은 시간을 보여줍니다.

## 현재 공개 버전

현재 Release는 **정식 배포 전 테스트 버전**입니다. 지인 테스트를 위해 설치 흐름과 기본 기능을 확인하는 단계이며, 사용 중 오류가 발생할 수 있습니다.

- 버전: `1.0.0`
- 지원 OS: macOS 13 이상
- 지원 CPU: Apple Silicon(`arm64`)
- Intel `x86_64` 및 Windows 빌드: 현재 제공하지 않음

## 다운로드 및 설치

1. [GitHub Releases](https://github.com/yunhachoi/Limitly/releases)에서 `Limitly-<버전>.dmg`를 내려받습니다.
2. DMG를 열고 `Limitly.app`을 `Applications` 폴더로 드래그합니다.
3. `/Applications/Limitly.app`을 실행합니다.

현재 테스트 배포본은 ad hoc 서명 상태이므로 첫 실행 때 macOS 보안 안내가 표시될 수 있습니다. 이 경우 앱을 Applications에 복사한 뒤 Finder에서 앱을 우클릭하고 **열기**를 선택합니다.

## Codex 연결 및 개인정보

Limitly는 OpenAI API 키나 별도 Limitly 계정을 요구하지 않습니다. 각 Mac에 설치된 공식 Codex 앱의 로컬 app-server 세션을 사용해 현재 로그인한 계정의 한도를 조회합니다. 비밀번호·쿠키·계정 토큰을 복사하거나 저장하지 않습니다.

따라서 사용자마다 자신의 Codex 로그인 계정에 해당하는 한도가 표시됩니다. 사용량을 보려면 공식 Codex 앱이 설치되어 있고 로그인되어 있어야 합니다.

## Release의 소스 코드 ZIP/TAR.GZ

GitHub는 태그가 있는 Release를 만들면 해당 태그 시점의 저장소 파일을 `Source code (zip)`과 `Source code (tar.gz)`로 자동 생성합니다. 이 파일은 별도로 업로드한 설치 파일이 아니며, GitHub가 제공하는 소스 스냅샷입니다. 현재 공개 저장소에는 배포 안내용 README만 있으므로 v1.0.0 소스 압축 파일에도 README만 들어 있습니다.

## 배포 파일

- 테스트 Release: [Limitly 1.0.0 — 정식 배포 전 테스트 버전](https://github.com/yunhachoi/Limitly/releases/tag/v1.0.0)
- DMG: [Limitly-1.0.0.dmg](https://github.com/yunhachoi/Limitly/releases/download/v1.0.0/Limitly-1.0.0.dmg)
- DMG SHA-256: `e2ed6a127b5d60bb8863739bec62f50c4a316323889fe75bfec7cc2ac5f24cb4`

개발용 소스와 SwiftPM 빌드 자료는 원래 프로젝트 폴더에서 관리합니다. 정식 배포 시 서명·공증 상태와 공개할 소스 범위를 다시 정리합니다.
