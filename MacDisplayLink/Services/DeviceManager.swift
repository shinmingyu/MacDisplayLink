//
//  DeviceManager.swift
//  MacDisplayLink
//
//  Created by Claude on 12/22/25.
//

import AVFoundation
import Combine

/// 캡쳐 디바이스 관리 서비스
/// 외부 캡쳐 카드 인식 및 연결/해제 감지
class DeviceManager: ObservableObject {
    @Published var captureDevices: [AVCaptureDevice] = []
    @Published var selectedDevice: AVCaptureDevice?

    private var observers: [NSObjectProtocol] = []

    init() {
        // 초기 디바이스 목록 로드
        refreshDevices()

        // 디바이스 연결/해제 감지 옵저버 등록
        setupDeviceObservers()
    }

    deinit {
        // 옵저버 제거
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    /// 디바이스 목록 새로고침
    func refreshDevices() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // 외부 캡쳐 디바이스만 필터링 (내장 카메라 제외)
            let discoverySession = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.externalUnknown],
                mediaType: .video,
                position: .unspecified
            )

            self.captureDevices = discoverySession.devices.filter { device in
                // 내장 카메라 제외 (.external 위치 확인)
                guard device.position == .unspecified else { return false }

                // 가상 카메라 제외 (OBS Virtual Camera 등)
                let deviceName = device.localizedName.lowercased()
                if deviceName.contains("virtual") || deviceName.contains("obs") {
                    print("  ⛔️ 제외: \(device.localizedName) (가상 카메라)")
                    return false
                }

                // iPhone Continuity Camera 제외 (무선 카메라)
                if deviceName.contains("iphone") || deviceName.contains("ipad") {
                    print("  ⛔️ 제외: \(device.localizedName) (무선 카메라)")
                    return false
                }

                // 실제 USB 캡쳐 디바이스만 포함
                return true
            }

            // 디버그: 발견된 디바이스 목록 출력
            print("🔍 [DeviceManager] 디바이스 검색 완료")
            print("📱 발견된 디바이스 수: \(self.captureDevices.count)")
            for (index, device) in self.captureDevices.enumerated() {
                print("  \(index + 1). \(device.localizedName) (ID: \(device.uniqueID))")
            }

            // 디바이스가 있고 선택된 디바이스가 없으면 첫 번째 디바이스 자동 선택
            if !self.captureDevices.isEmpty && self.selectedDevice == nil {
                self.selectedDevice = self.captureDevices.first
                print("✅ 첫 번째 디바이스 자동 선택: \(self.selectedDevice?.localizedName ?? "Unknown")")
            }

            // 선택된 디바이스가 목록에 없으면 nil로 설정
            if let selected = self.selectedDevice,
               !self.captureDevices.contains(where: { $0.uniqueID == selected.uniqueID }) {
                print("⚠️ 선택된 디바이스가 연결 해제됨: \(selected.localizedName)")
                self.selectedDevice = nil
            }
        }
    }

    /// 디바이스 연결/해제 감지 옵저버 설정
    private func setupDeviceObservers() {
        // 디바이스 연결 감지
        let connectedObserver = NotificationCenter.default.addObserver(
            forName: .AVCaptureDeviceWasConnected,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.refreshDevices()
        }

        // 디바이스 해제 감지
        let disconnectedObserver = NotificationCenter.default.addObserver(
            forName: .AVCaptureDeviceWasDisconnected,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.refreshDevices()
        }

        observers.append(connectedObserver)
        observers.append(disconnectedObserver)
    }

    /// 디바이스 선택
    func selectDevice(_ device: AVCaptureDevice) {
        DispatchQueue.main.async { [weak self] in
            self?.selectedDevice = device
            print("✅ 디바이스 선택됨: \(device.localizedName)")
        }
    }
}
