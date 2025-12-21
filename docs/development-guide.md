# MacDisplayLink 개발 가이드

## 📋 프로젝트 개요

macOS에서 캡쳐 카드를 통해 외부 영상/음성 소스(PlayStation, Nintendo Switch 등)를 실시간으로 프리뷰하고 녹화할 수 있는 애플리케이션

### 🎯 핵심 목표
게임기를 맥북의 고품질 디스플레이로 즐기고 싶은 일반 사용자를 위한 **미니멀하고 직관적인** 캡쳐 솔루션

### 🎨 차별점
- OBS와 달리 복잡한 설정이 없는 **심플한 UI/UX**
- 게임 플레이에 최적화된 **낮은 지연 시간** (100ms 이하 목표)
- App Store 출시를 통한 **쉬운 설치와 업데이트**

---

## 🛠️ 기술 스택

### 플랫폼 & 언어
- **macOS**: 13.0 (Ventura) 이상
- **Swift**: 최신 버전
- **SwiftUI**: UI 프레임워크

### 프레임워크
- **AVFoundation**: 비디오/오디오 캡쳐 및 녹화
- **CoreMedia**: 미디어 데이터 처리
- **UserDefaults**: 설정 저장

### 아키텍처
- **MVVM (Model-View-ViewModel)**: 테스트 가능하고 유지보수가 쉬운 구조

### 주요 클래스
- `AVCaptureDevice`: 캡쳐 디바이스 인식
- `AVCaptureSession`: 캡쳐 세션 관리
- `AVCaptureVideoDataOutput`: 비디오 데이터 출력
- `AVCaptureAudioDataOutput`: 오디오 데이터 출력
- `AVSampleBufferAudioRenderer`: 오디오 재생
- `AVAssetWriter`: 미디어 파일 저장

---

## 🎯 핵심 기능 명세

### 1️⃣ 캡쳐 디바이스 인식 및 관리

**요구사항:**
- 맥에 연결된 외부 캡쳐 카드 자동 인식
- 내장 카메라는 목록에서 제외
- 여러 캡쳐 카드 연결 시: 첫 번째 자동 선택 + 설정에서 변경 가능
- 디바이스 연결/해제 실시간 감지

**기술 구현:**
- `AVCaptureDevice.DiscoverySession`으로 `.external` 디바이스만 필터링
- `AVCaptureDevice.wasConnectedNotification` / `wasDisconnectedNotification` 감지

---

### 2️⃣ 실시간 비디오 프리뷰

**요구사항:**
- 캡쳐 카드에서 들어오는 영상을 실시간으로 화면에 표시
- **지연 시간**: 100ms 이하 목표, 150ms 최대 허용 (OBS 수준)
- 입력 신호 정보 표시 (현재 해상도/프레임레이트)
- 신호 없음 상태: 📡 아이콘 + "No Signal" 텍스트 표시

**기술 구현:**
- `AVCaptureVideoDataOutput`로 실시간 프레임 수신
- SwiftUI `Image`로 프레임 렌더링 (CoreImage 활용)
- 지연 최소화를 위해 `.alwaysDiscardsLateVideoFrames = true` 설정

**UI 동작:**
- 창 크기 조절 시 **비율 유지 (letterbox)**: 16:9 비율 유지
- 최소 크기: 1280×720 (720p)
- 최대 크기: 제한 없음
- 프리뷰 클릭: 토글 방식으로 컨트롤 표시/숨김

---

### 3️⃣ 오디오 입력 및 모니터링

**요구사항:**
- 캡쳐 카드에서 들어오는 오디오를 스피커로 실시간 출력
- 오디오 레벨 인디케이터: 수평 레벨 바 (녹색→노란색→빨간색)
- 오디오 볼륨 조절: 시스템 볼륨에 의존 (별도 UI 없음)

**기술 구현:**
- `AVCaptureAudioDataOutput`로 오디오 데이터 수신
- `AVSampleBufferAudioRenderer`로 실시간 재생
- 오디오 레벨 계산: RMS (Root Mean Square) 방식

**지원 범위:**
- 입력 소스: 캡쳐 카드 오디오만
- 샘플링 레이트: 캡쳐 카드 기본값 사용

---

### 4️⃣ 녹화 및 저장

**요구사항:**
- 영상 + 음성 동시 녹화
- 녹화 버튼: ⏺ (시작) ↔ ⏹ (정지) 토글
- 녹화 시간 표시 (파일 크기는 표시 안 함)
- 자동 파일명 생성: `MacDisplayLink_20250115_143025.mp4`

**저장 설정:**
- **경로**: `~/Library/Containers/com.echo.MacDisplayLink/Data/Documents/MacDisplayLink/`
  - App Store 샌드박스 정책 준수
  - "Finder에서 보기" 버튼 제공
- **포맷**: MP4 고정
- **코덱**: H.264 고정
- **기본 녹화 설정**: 1080p 60fps (설정에서 변경 가능)
- **비디오 비트레이트**: 12000 kbps (기본값)
- **오디오 비트레이트**: 192 kbps (기본값)

**기술 구현:**
- `AVAssetWriter`로 비디오/오디오 동시 인코딩
- 실시간 녹화 상태 모니터링 (녹화 시간, 파일 크기)

**예외 처리:**
- 녹화 중 캡쳐카드 연결 해제: 즉시 정지 + 파일 저장 + Alert 표시
- 앱 종료 시: 경고 없이 즉시 종료 + 녹화 파일 자동 저장
- 디스크 공간 부족: 녹화 자동 정지 + Alert

---

### 5️⃣ 설정 (Settings Sheet)

**UI 구조:**
- 탭 스타일: **영상 / 오디오 / 저장** 3개 탭
- 설정 변경 시 **즉시 적용** (Save 버튼 없음)

#### 📹 영상 설정 탭
- **입력 해상도**: 자동 감지 (기본) + 수동 선택 가능
- **녹화 해상도**: 입력과 동일 (기본) + 수동 선택 가능
  - 옵션: 720p, 1080p, 1440p, 4K
- **프레임레이트**: 30fps, 60fps, 120fps 선택
- **비디오 비트레이트**: 슬라이더 (5000~20000 kbps)
  - 기본값: 12000 kbps

#### 🔊 오디오 설정 탭
- **오디오 입력 소스**: 캡쳐 카드 (고정)
- **오디오 비트레이트**: 128 kbps, 192 kbps, 256 kbps
  - 기본값: 192 kbps

#### 💾 저장 설정 탭
- **저장 경로 정보**: 현재 저장 경로 표시 (읽기 전용)
- **"Finder에서 보기" 버튼**: 저장 폴더를 Finder로 오픈
- **파일명 형식**: `MacDisplayLink_YYYYMMDD_HHMMSS.mp4` (고정)

---

## 🎨 UI/UX 상세 명세

### 메인 화면 (기본 상태)
```
┌─────────────────────────────────┐
│                                 │
│                                 │
│      [비디오 프리뷰 영역]          │
│         (16:9 비율)              │
│                                 │
│                                 │
└─────────────────────────────────┘
```
- 검은 배경에 비디오 프리뷰만 표시
- 신호 없음 시: 📡 + "No Signal" 중앙 표시

### 메인 화면 (컨트롤 표시 상태)
```
┌─────────────────────────────────┐
│  ⚙️ 설정                         │
│                                 │
│      [비디오 프리뷰 영역]          │
│                                 │
│  ━━━━━━━━━━  [🔴 ⏺]  00:05:23   │
│  오디오 레벨    녹화    녹화시간    │
└─────────────────────────────────┘
```
- 프리뷰 클릭 시 토글 (표시 ↔ 숨김)
- 왼쪽: 설정 버튼 (⚙️)
- 하단 왼쪽: 오디오 레벨 바 (수평)
- 하단 중앙: 녹화 버튼 (⏺ → ⏹)
- 하단 오른쪽: 녹화 시간 (00:00:00)

### 설정 Sheet
```
┌─────────────────────────────────┐
│  영상  │  오디오  │  저장        │
├─────────────────────────────────┤
│                                 │
│  [영상 설정 내용]                 │
│                                 │
│  - 입력 해상도: 자동 ▼            │
│  - 녹화 해상도: 1080p ▼          │
│  - 프레임레이트: 60fps ▼          │
│  - 비트레이트: ━━●━━ 12000 kbps  │
│                                 │
└─────────────────────────────────┘
```

---

## ⚠️ 에러 처리 명세

### 필수 에러 핸들링

| 상황 | 동작 | 표시 방법 |
|------|------|-----------|
| 캡쳐 카드 미연결 | 프리뷰 불가, 안내 메시지 | macOS Alert |
| 신호 없음 | 프리뷰에 "No Signal" 표시 | 인라인 오버레이 |
| 녹화 중 연결 해제 | 즉시 정지 + 파일 저장 | macOS Alert |
| 디스크 공간 부족 | 녹화 자동 정지 | macOS Alert |
| 권한 거부 (카메라/마이크) | 설정 앱으로 이동 안내 | macOS Alert |
| 지원 안 되는 해상도 | 가장 가까운 지원 해상도 사용 | macOS Alert |

---

## 🔐 권한 및 Entitlements

### Info.plist 설정
```xml
<key>NSCameraUsageDescription</key>
<string>캡쳐 카드의 비디오 입력을 받기 위해 카메라 권한이 필요합니다.</string>

<key>NSMicrophoneUsageDescription</key>
<string>캡쳐 카드의 오디오 입력을 받기 위해 마이크 권한이 필요합니다.</string>
```

### Entitlements (App Sandbox)
```xml
<key>com.apple.security.app-sandbox</key>
<true/>

<key>com.apple.security.device.audio-input</key>
<true/>

<key>com.apple.security.device.camera</key>
<true/>

<key>com.apple.security.files.user-selected.read-write</key>
<true/>
```

---

## 🗓️ 개발 로드맵

### Phase 1: MVP (최소 기능 제품) ⭐ **최우선**
**목표: 기본적인 캡쳐 및 녹화 기능 구현 + 즉시 테스트**

**Step 1.1: 프로젝트 설정**
- [ ] Xcode 프로젝트 생성 및 기본 설정
- [ ] Info.plist 권한 추가
- [ ] Entitlements 설정
- [ ] MVVM 기본 구조 생성

**Step 1.2: 캡쳐 디바이스 인식**
- [ ] `AVCaptureDevice` 열거 및 필터링
- [ ] 외부 캡쳐 카드만 선택
- [ ] 디바이스 연결/해제 감지
- [ ] ✅ **테스트**: 캡쳐카드 인식 확인

**Step 1.3: 비디오 프리뷰**
- [ ] `AVCaptureSession` 구성
- [ ] 비디오 입력 스트림 수신
- [ ] SwiftUI로 프리뷰 렌더링
- [ ] 신호 없음 상태 표시
- [ ] ✅ **테스트**: 화면에 영상 표시 확인

**Step 1.4: 오디오 모니터링**
- [ ] 오디오 입력 스트림 수신
- [ ] `AVSampleBufferAudioRenderer`로 재생
- [ ] 오디오 레벨 미터 구현
- [ ] ✅ **테스트**: 소리 출력 확인

**Step 1.5: 기본 녹화**
- [ ] `AVAssetWriter` 구성
- [ ] 녹화 시작/정지 로직
- [ ] MP4 파일 저장 (H.264, 기본 설정)
- [ ] 자동 파일명 생성
- [ ] ✅ **테스트**: 녹화 파일 재생 확인

**Step 1.6: 기본 UI**
- [ ] 프리뷰 화면 레이아웃
- [ ] 녹화 버튼 (⏺/⏹)
- [ ] 녹화 시간 표시
- [ ] 컨트롤 토글 기능
- [ ] ✅ **테스트**: UI 동작 확인

---

### Phase 2: 설정 및 제어
**목표: 사용자 설정 기능 추가**

- [ ] 설정 Sheet UI (탭 스타일)
- [ ] 해상도/프레임레이트 선택
- [ ] 비트레이트 조절
- [ ] 오디오 비트레이트 선택
- [ ] "Finder에서 보기" 버튼
- [ ] UserDefaults 저장/불러오기
- [ ] ✅ **테스트**: 설정 변경 및 저장 확인

---

### Phase 3: 완성도 향상
**목표: 에러 처리 및 사용성 개선**

- [ ] 에러 Alert 구현
- [ ] 디스크 공간 확인
- [ ] 권한 요청 플로우
- [ ] 창 크기 제한 적용
- [ ] 성능 최적화 (지연 시간 측정)
- [ ] ✅ **테스트**: 예외 상황 처리 확인

---

### Phase 4: 출시 준비
**목표: App Store 배포 준비**

- [ ] 앱 아이콘 제작 (맥북 + HDMI 캡쳐카드)
- [ ] 스크린샷 촬영
- [ ] App Store 설명 작성
- [ ] 베타 테스트 (TestFlight)
- [ ] 메모리 누수 체크
- [ ] 다양한 캡쳐 카드 테스트
- [ ] App Store 제출

---

## 📝 개발 체크리스트

### 시작하기 전
- [ ] macOS 13+ 개발 환경 확인
- [ ] Xcode 최신 버전 설치
- [ ] 캡쳐 카드 준비 및 연결 테스트

### 개발 중
- [ ] 각 Step 완료 시 **즉시 빌드 & 테스트**
- [ ] 커밋 시 `docs/commit-guide.md` 준수
- [ ] 기능 브랜치 사용 (`docs/branch-guide.md` 참고)

### 배포 전
- [ ] 모든 에러 처리 시나리오 테스트
- [ ] 메모리 누수 체크 (Instruments)
- [ ] 다양한 캡쳐 카드로 테스트
- [ ] 720p~4K, 30~120fps 테스트
- [ ] 지연 시간 측정 (100ms 이하 확인)

---

## 📚 참고 자료

### Apple 공식 문서
- [AVFoundation Programming Guide](https://developer.apple.com/av-foundation/)
- [AVCaptureSession](https://developer.apple.com/documentation/avfoundation/avcapturesession)
- [AVAssetWriter](https://developer.apple.com/documentation/avfoundation/avassetwriter)
- [App Sandbox](https://developer.apple.com/documentation/security/app_sandbox)

### 샘플 프로젝트
- [AVCam: Building a Camera App](https://developer.apple.com/documentation/avfoundation/avcam_building_a_camera_app)

---

## 🔄 문서 업데이트

이 문서는 프로젝트 진행에 따라 지속적으로 업데이트됩니다.
- 새로운 기능 추가 시 명세 업데이트
- 기술적 결정 사항 기록
- 테스트 결과 반영

**최종 업데이트**: 2025-01-21
