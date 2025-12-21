# MacDisplayLink 작업 목록

이 문서는 `docs/development-guide.md`를 기준으로 한 실행 가능한 Task 목록입니다.

---

## 📊 진행 상황 추적

| Phase | 상태 | 진행률 | 비고 |
|-------|------|--------|------|
| Phase 1: MVP | 🔴 대기 | 0% | |
| Phase 2: 설정 및 제어 | 🔴 대기 | 0% | |
| Phase 3: 완성도 향상 | 🔴 대기 | 0% | |
| Phase 4: 출시 준비 | 🔴 대기 | 0% | |

상태 범례:
- 🔴 대기
- 🟡 진행중
- 🟢 완료
- ⚪ 보류

---

## Phase 1: MVP (최소 기능 제품) ⭐

**목표**: 캡쳐카드 인식 + 프리뷰 + 사운드 출력 + 녹화 + 설정

---

### Step 1.1: 프로젝트 설정

#### 환경 설정
- [ ] macOS 13+ 개발 환경 확인
- [ ] Xcode 최신 버전 설치 확인
- [ ] 캡쳐 카드 연결 테스트

#### 프로젝트 생성
- [ ] Xcode에서 새 macOS App 프로젝트 생성
  - Project Name: `MacDisplayLink`
  - Organization Identifier: `com.echo`
  - Interface: SwiftUI
  - Language: Swift
  - Minimum Deployment: macOS 13.0

#### Info.plist 권한 추가
- [ ] `NSCameraUsageDescription` 추가
  - 값: "캡쳐 카드의 비디오 입력을 받기 위해 카메라 권한이 필요합니다."
- [ ] `NSMicrophoneUsageDescription` 추가
  - 값: "캡쳐 카드의 오디오 입력을 받기 위해 마이크 권한이 필요합니다."

#### Entitlements 설정
- [ ] App Sandbox 활성화
  - `com.apple.security.app-sandbox` = YES
- [ ] 카메라 권한 추가
  - `com.apple.security.device.camera` = YES
- [ ] 마이크 권한 추가
  - `com.apple.security.device.audio-input` = YES
- [ ] 파일 읽기/쓰기 권한 추가
  - `com.apple.security.files.user-selected.read-write` = YES

#### MVVM 기본 구조 생성
- [ ] 폴더 구조 생성
  ```
  MacDisplayLink/
  ├── Models/
  ├── Views/
  ├── ViewModels/
  └── Services/
  ```

#### ✅ 테스트
- [ ] 프로젝트 빌드 성공 확인
- [ ] 앱 실행 시 기본 SwiftUI 화면 표시 확인

---

### Step 1.2: 캡쳐 디바이스 인식

#### DeviceManager 서비스 구현
- [ ] `Services/DeviceManager.swift` 생성
  - `@Published var captureDevices: [AVCaptureDevice]`
  - `func refreshDevices()` 메서드 구현
  - `.external` 타입 디바이스만 필터링
  - 내장 카메라 제외 로직 추가

#### 디바이스 연결/해제 감지
- [ ] `AVCaptureDevice.wasConnectedNotification` 옵저버 등록
- [ ] `AVCaptureDevice.wasDisconnectedNotification` 옵저버 등록
- [ ] 디바이스 목록 자동 새로고침 구현

#### ViewModel 구현
- [ ] `ViewModels/DeviceViewModel.swift` 생성
  - DeviceManager를 주입받아 디바이스 목록 관리
  - `@Published var selectedDevice: AVCaptureDevice?`

#### ✅ 테스트
- [ ] 캡쳐카드 연결 시 목록에 표시 확인
- [ ] 캡쳐카드 연결 해제 시 목록에서 제거 확인
- [ ] 내장 카메라가 목록에 없는지 확인
- [ ] 콘솔 로그로 디바이스 정보 출력 확인

---

### Step 1.3: 비디오 프리뷰

#### CaptureSessionManager 서비스 구현
- [ ] `Services/CaptureSessionManager.swift` 생성
  - `AVCaptureSession` 인스턴스 관리
  - `func configureSession(device: AVCaptureDevice)` 구현
  - `AVCaptureVideoDataOutput` 추가
  - `.alwaysDiscardsLateVideoFrames = true` 설정

#### 프레임 처리 및 렌더링
- [ ] `AVCaptureVideoDataOutputSampleBufferDelegate` 구현
  - `didOutput sampleBuffer` 콜백에서 프레임 수신
  - `CVPixelBuffer`를 `CIImage`로 변환
  - `CIImage`를 `CGImage`로 변환
  - SwiftUI `Image`로 변환

#### PreviewViewModel 구현
- [ ] `ViewModels/PreviewViewModel.swift` 생성
  - `@Published var currentFrame: Image?`
  - `@Published var hasSignal: Bool`
  - `@Published var signalInfo: String?` (해상도/프레임레이트)
  - 신호 정보 파싱 로직

#### PreviewView 구현
- [ ] `Views/PreviewView.swift` 생성
  - `Image` 표시 (aspectRatio로 16:9 유지)
  - 신호 없음 시: 📡 + "No Signal" 오버레이
  - 배경색: 검은색

#### 창 크기 제한
- [ ] 최소 크기 설정: 1280×720
  - `.frame(minWidth: 1280, minHeight: 720)`

#### ✅ 테스트
- [ ] 캡쳐카드 연결 후 영상이 화면에 표시되는지 확인
- [ ] 신호 없음 상태에서 "No Signal" 표시 확인
- [ ] 창 크기 조절 시 16:9 비율 유지 확인 (letterbox)
- [ ] 입력 신호 정보 표시 확인 (해상도/fps)

---

### Step 1.4: 오디오 모니터링

#### AudioCaptureManager 서비스 구현
- [ ] `Services/AudioCaptureManager.swift` 생성
  - `AVCaptureSession`에 오디오 입력 추가
  - `AVCaptureAudioDataOutput` 추가
  - `AVSampleBufferAudioRenderer` 초기화

#### 오디오 실시간 재생
- [ ] `AVCaptureAudioDataOutputSampleBufferDelegate` 구현
  - `didOutput sampleBuffer` 콜백에서 오디오 수신
  - `AVSampleBufferAudioRenderer.enqueue(sampleBuffer)` 호출

#### 오디오 레벨 계산
- [ ] RMS (Root Mean Square) 방식으로 레벨 계산
  - `CMSampleBuffer`에서 오디오 데이터 추출
  - PCM 데이터를 Float 배열로 변환
  - RMS 값 계산 (0.0 ~ 1.0)

#### AudioViewModel 구현
- [ ] `ViewModels/AudioViewModel.swift` 생성
  - `@Published var audioLevel: Float` (0.0 ~ 1.0)
  - 레벨 값을 색상으로 매핑 (녹색 → 노란색 → 빨간색)

#### AudioLevelView 구현
- [ ] `Views/AudioLevelView.swift` 생성
  - 수평 레벨 바 (ProgressView 또는 커스텀 뷰)
  - 0.0~0.6: 녹색
  - 0.6~0.8: 노란색
  - 0.8~1.0: 빨간색

#### ✅ 테스트
- [ ] 캡쳐카드에서 오디오가 스피커로 출력되는지 확인
- [ ] 오디오 레벨 바가 소리에 반응하는지 확인
- [ ] 소리가 클 때 빨간색으로 변하는지 확인

---

### Step 1.5: 기본 녹화

#### RecordingManager 서비스 구현
- [ ] `Services/RecordingManager.swift` 생성
  - `AVAssetWriter` 인스턴스 관리
  - `func startRecording()` 구현
  - `func stopRecording()` 구현
  - `@Published var isRecording: Bool`
  - `@Published var recordingDuration: TimeInterval`

#### 파일 저장 경로 설정
- [ ] 저장 폴더 생성 로직
  - 경로: `~/Library/Containers/com.echo.MacDisplayLink/Data/Documents/MacDisplayLink/`
  - 폴더 없으면 자동 생성

#### 자동 파일명 생성
- [ ] 파일명 포맷: `MacDisplayLink_YYYYMMDD_HHMMSS.mp4`
  - `DateFormatter` 사용
  - 타임스탬프 포맷: `yyyyMMdd_HHmmss`

#### 비디오/오디오 인코딩
- [ ] `AVAssetWriterInput` 생성 (비디오)
  - 코덱: H.264 (kCMVideoCodecType_H264)
  - 비트레이트: 12000 kbps (기본값)
  - 해상도: 1080p (기본값)
  - 프레임레이트: 60fps (기본값)
- [ ] `AVAssetWriterInput` 생성 (오디오)
  - 포맷: AAC
  - 비트레이트: 192 kbps (기본값)

#### 샘플 버퍼 쓰기
- [ ] 비디오 프레임을 `AVAssetWriter`에 추가
- [ ] 오디오 샘플을 `AVAssetWriter`에 추가
- [ ] 타이밍 동기화 처리

#### RecordingViewModel 구현
- [ ] `ViewModels/RecordingViewModel.swift` 생성
  - `@Published var isRecording: Bool`
  - `@Published var recordingTime: String` (포맷: "00:05:23")
  - `func toggleRecording()` 메서드

#### ✅ 테스트
- [ ] 녹화 시작 후 파일이 생성되는지 확인
- [ ] 녹화 정지 후 파일이 재생되는지 확인
- [ ] 영상과 음성이 모두 녹화되는지 확인
- [ ] 파일명 형식이 올바른지 확인

---

### Step 1.6: 기본 UI

#### MainView 레이아웃 구성
- [ ] `Views/MainView.swift` 생성
  - PreviewView (ZStack으로 오버레이)
  - 컨트롤 표시/숨김 토글 상태 관리
  - `@State var showControls: Bool = false`

#### 컨트롤 오버레이 구현
- [ ] `Views/ControlsOverlay.swift` 생성
  - 왼쪽 상단: 설정 버튼 (⚙️)
  - 하단 왼쪽: AudioLevelView
  - 하단 중앙: RecordButton
  - 하단 오른쪽: 녹화 시간 표시

#### RecordButton 구현
- [ ] `Views/RecordButton.swift` 생성
  - 녹화 전: ⏺ (빨간 원)
  - 녹화 중: ⏹ (빨간 사각형)
  - 애니메이션: 녹화 중 펄스 효과

#### 프리뷰 클릭 제스처
- [ ] `.onTapGesture` 추가
  - `showControls.toggle()` 호출
  - 컨트롤 표시/숨김 애니메이션

#### 녹화 시간 포맷팅
- [ ] `formatDuration(_ duration: TimeInterval) -> String`
  - 포맷: "00:05:23" (hh:mm:ss)

#### ✅ 테스트
- [ ] 프리뷰 클릭 시 컨트롤이 표시/숨김되는지 확인
- [ ] 녹화 버튼 클릭 시 ⏺ ↔ ⏹ 전환 확인
- [ ] 녹화 시간이 실시간으로 업데이트되는지 확인
- [ ] 레이아웃이 깔끔하게 표시되는지 확인

---

## Phase 2: 설정 및 제어

**목표**: 사용자가 설정을 변경할 수 있는 UI 제공

---

### 설정 Sheet UI

#### SettingsView 생성
- [ ] `Views/SettingsView.swift` 생성
  - TabView로 3개 탭 구성
  - 탭 1: 📹 영상
  - 탭 2: 🔊 오디오
  - 탭 3: 💾 저장

#### 영상 설정 탭
- [ ] 입력 해상도 선택
  - Picker: 자동 / 720p / 1080p / 1440p / 4K
- [ ] 녹화 해상도 선택
  - Picker: 입력과 동일 / 720p / 1080p / 1440p / 4K
- [ ] 프레임레이트 선택
  - Picker: 30fps / 60fps / 120fps
- [ ] 비디오 비트레이트 슬라이더
  - 범위: 5000~20000 kbps
  - 기본값: 12000 kbps
  - 실시간 값 표시

#### 오디오 설정 탭
- [ ] 오디오 입력 소스 (읽기 전용)
  - Text: "캡쳐 카드"
- [ ] 오디오 비트레이트 선택
  - Picker: 128 kbps / 192 kbps / 256 kbps

#### 저장 설정 탭
- [ ] 저장 경로 표시 (읽기 전용)
  - Text: 현재 저장 경로
- [ ] "Finder에서 보기" 버튼
  - `NSWorkspace.shared.selectFile()` 호출
- [ ] 파일명 형식 표시 (읽기 전용)
  - Text: "MacDisplayLink_YYYYMMDD_HHMMSS.mp4"

#### SettingsViewModel 구현
- [ ] `ViewModels/SettingsViewModel.swift` 생성
  - `@Published var inputResolution: Resolution`
  - `@Published var recordingResolution: Resolution`
  - `@Published var frameRate: FrameRate`
  - `@Published var videoBitrate: Int`
  - `@Published var audioBitrate: Int`
  - UserDefaults 저장/불러오기 로직

#### UserDefaults 저장
- [ ] 설정값을 UserDefaults에 저장
  - 키: "inputResolution", "recordingResolution", etc.
- [ ] 앱 시작 시 UserDefaults에서 불러오기

#### 설정 버튼 연결
- [ ] MainView에서 설정 버튼 클릭 시 Sheet 표시
  - `.sheet(isPresented: $showSettings)`

#### ✅ 테스트
- [ ] 설정 Sheet가 정상적으로 표시되는지 확인
- [ ] 각 설정값 변경 시 즉시 반영되는지 확인
- [ ] 앱 재시작 후 설정값이 유지되는지 확인
- [ ] "Finder에서 보기" 버튼 클릭 시 폴더가 열리는지 확인

---

## Phase 3: 완성도 향상

**목표**: 에러 처리 및 사용성 개선

---

### 에러 처리

#### Alert 시스템 구현
- [ ] `Models/AlertMessage.swift` 생성
  - `struct AlertMessage: Identifiable`
  - `title`, `message` 프로퍼티

#### 에러 상황별 Alert
- [ ] 캡쳐 카드 미연결
  - Alert: "캡쳐 카드가 연결되지 않았습니다."
- [ ] 녹화 중 연결 해제
  - 녹화 즉시 정지 + 파일 저장
  - Alert: "캡쳐 카드 연결이 해제되어 녹화가 중지되었습니다."
- [ ] 디스크 공간 부족
  - 녹화 자동 정지
  - Alert: "디스크 공간이 부족하여 녹화가 중지되었습니다."
- [ ] 권한 거부
  - Alert: "카메라/마이크 권한이 필요합니다. 시스템 설정에서 권한을 허용해주세요."
  - "설정 열기" 버튼 → 시스템 설정 앱 오픈

#### 디스크 공간 확인
- [ ] `FileManager.default.attributesOfFileSystem()` 사용
  - 남은 공간 확인
  - 1GB 이하 시 경고

#### 권한 요청 플로우
- [ ] 앱 시작 시 권한 확인
  - `AVCaptureDevice.authorizationStatus(for: .video)`
  - `AVCaptureDevice.authorizationStatus(for: .audio)`
- [ ] 권한 없으면 요청
  - `AVCaptureDevice.requestAccess(for: .video)`
  - `AVCaptureDevice.requestAccess(for: .audio)`

#### ✅ 테스트
- [ ] 캡쳐카드 연결 해제 시 Alert 표시 확인
- [ ] 권한 거부 시 Alert 표시 확인
- [ ] 디스크 공간 부족 시 녹화 정지 확인

---

### 성능 최적화

#### 지연 시간 측정
- [ ] 비디오 프레임 타임스탬프 기록
- [ ] 렌더링 완료 시점 기록
- [ ] 지연 시간 계산 (ms 단위)
- [ ] 콘솔 로그로 출력

#### 프레임 드롭 최소화
- [ ] 백그라운드 큐에서 프레임 처리
- [ ] 메인 스레드에서는 UI 업데이트만 수행

#### 메모리 관리
- [ ] `@Published` 프로퍼티 메인 스레드에서 업데이트
- [ ] Weak reference 사용 (`[weak self]`)

#### ✅ 테스트
- [ ] 지연 시간이 100ms 이하인지 확인
- [ ] 메모리 누수가 없는지 Instruments로 확인
- [ ] CPU 사용률 확인

---

## Phase 4: 출시 준비

**목표**: App Store 배포

---

### 앱 아이콘 제작
- [ ] 디자인: 맥북 화면 + HDMI 캡쳐카드 모양
- [ ] 사이즈: 1024×1024 (App Store용)
- [ ] Assets에 추가

### 스크린샷 촬영
- [ ] 메인 화면 (프리뷰)
- [ ] 설정 화면
- [ ] 녹화 중 화면
- [ ] 최소 5장 준비

### App Store 설명 작성
- [ ] 한글 설명
- [ ] 영문 설명
- [ ] 키워드 선정

### 베타 테스트
- [ ] TestFlight 빌드 업로드
- [ ] 베타 테스터 초대
- [ ] 피드백 수집

### 최종 테스트
- [ ] 다양한 캡쳐 카드로 테스트
  - Elgato HD60 S
  - AVerMedia Live Gamer Portable
  - 기타 HDMI 캡쳐 카드
- [ ] 다양한 해상도/프레임레이트 테스트
  - 720p 30fps
  - 1080p 60fps
  - 4K 30fps
- [ ] 메모리 누수 체크 (Instruments)
- [ ] 장시간 녹화 테스트 (1시간 이상)

### App Store 제출
- [ ] App Store Connect 등록
- [ ] 빌드 업로드
- [ ] 심사 제출
- [ ] 승인 대기

---

## 📝 개발 가이드라인

### 커밋 규칙
- 커밋 메시지: `docs/commit-guide.md` 준수
- 각 Step 완료 시 커밋
- 테스트 통과 후 커밋

### 브랜치 전략
- `docs/branch-guide.md` 참고
- feature 브랜치에서 작업
- develop에 머지

### 테스트 우선
- **각 Step 완료 후 즉시 빌드 & 테스트**
- 문제 발견 시 즉시 수정
- 다음 Step으로 넘어가기 전에 완벽히 동작 확인

---

## 🔄 문서 업데이트

- 작업 완료 시 체크박스 체크
- 진행률 업데이트
- 이슈 발생 시 비고란에 기록

**최종 업데이트**: 2025-01-21
