//
//  DeviceViewModel.swift
//  MacDisplayLink
//
//  Created by Claude on 12/22/25.
//

import SwiftUI
import AVFoundation
import Combine

/// 디바이스 관리 ViewModel
/// DeviceManager를 통해 캡쳐 디바이스 상태 관리
class DeviceViewModel: ObservableObject {
    @Published var currentFrame: Image?
    @Published var hasSignal: Bool = false
    @Published var signalInfo: String = "No Signal"
    @Published var isDeviceConnected: Bool = false
    @Published var captureDevices: [AVCaptureDevice] = []
    @Published var selectedDevice: AVCaptureDevice?
    @Published var audioLevel: Float = 0.0
    @Published var isMuted: Bool = false
    @Published var availableFormats: [VideoFormat] = []

    private let deviceManager: DeviceManager
    private let captureSessionManager: CaptureSessionManager
    private var cancellables = Set<AnyCancellable>()

    init(deviceManager: DeviceManager = DeviceManager(), recordingManager: RecordingManager? = nil) {
        self.deviceManager = deviceManager
        self.captureSessionManager = CaptureSessionManager(recordingManager: recordingManager)

        // 디바이스 목록 변경 감지
        deviceManager.$captureDevices
            .sink { [weak self] devices in
                self?.captureDevices = devices
                self?.isDeviceConnected = !devices.isEmpty
            }
            .store(in: &cancellables)

        // 선택된 디바이스 변경 감지
        deviceManager.$selectedDevice
            .sink { [weak self] device in
                self?.selectedDevice = device
                self?.configureCaptureSession(for: device)
            }
            .store(in: &cancellables)

        // 사용 가능한 포맷 목록 변경 감지
        deviceManager.$availableFormats
            .sink { [weak self] formats in
                self?.availableFormats = formats
            }
            .store(in: &cancellables)

        // CaptureSessionManager의 프레임 변경 감지
        captureSessionManager.$currentFrame
            .sink { [weak self] cgImage in
                guard let cgImage = cgImage else {
                    self?.currentFrame = nil
                    return
                }
                #if canImport(AppKit)
                let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
                self?.currentFrame = Image(nsImage: nsImage)
                #endif
            }
            .store(in: &cancellables)

        // CaptureSessionManager의 신호 정보 변경 감지
        captureSessionManager.$hasSignal
            .sink { [weak self] hasSignal in
                self?.hasSignal = hasSignal
            }
            .store(in: &cancellables)

        captureSessionManager.$signalInfo
            .sink { [weak self] signalInfo in
                self?.signalInfo = signalInfo
            }
            .store(in: &cancellables)

        // CaptureSessionManager의 오디오 레벨 변경 감지
        captureSessionManager.$audioLevel
            .sink { [weak self] level in
                self?.audioLevel = level
            }
            .store(in: &cancellables)

        // CaptureSessionManager의 음소거 상태 변경 감지
        captureSessionManager.$isMuted
            .sink { [weak self] isMuted in
                self?.isMuted = isMuted
            }
            .store(in: &cancellables)
    }

    /// 캡쳐 세션 구성
    private func configureCaptureSession(for device: AVCaptureDevice?) {
        if let device = device {
            print("🎥 [DeviceViewModel] 캡쳐 세션 시작: \(device.localizedName)")
            captureSessionManager.configureSession(with: device)
        } else {
            print("⏹ [DeviceViewModel] 캡쳐 세션 중지")
            captureSessionManager.stopSession()
        }
    }

    /// 디바이스 새로고침
    func refreshDevices() {
        deviceManager.refreshDevices()
    }

    /// 디바이스 선택
    func selectDevice(_ device: AVCaptureDevice) {
        deviceManager.selectDevice(device)
    }

    /// 음소거 토글
    func toggleMute() {
        captureSessionManager.isMuted.toggle()
    }

    /// 입력 포맷 적용
    func applyInputFormat(_ formatId: String?) {
        let format = availableFormats.first { $0.id == formatId }
        captureSessionManager.applyVideoFormat(format)
    }
}
