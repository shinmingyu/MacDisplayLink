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

    private let deviceManager: DeviceManager
    private var cancellables = Set<AnyCancellable>()

    init(deviceManager: DeviceManager = DeviceManager()) {
        self.deviceManager = deviceManager

        // 디바이스 목록 변경 감지
        deviceManager.$captureDevices
            .sink { [weak self] devices in
                self?.captureDevices = devices
                self?.isDeviceConnected = !devices.isEmpty
                self?.updateSignalInfo()
            }
            .store(in: &cancellables)

        // 선택된 디바이스 변경 감지
        deviceManager.$selectedDevice
            .sink { [weak self] device in
                self?.selectedDevice = device
                self?.updateSignalInfo()
            }
            .store(in: &cancellables)
    }

    /// 신호 정보 업데이트
    private func updateSignalInfo() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            if let device = self.deviceManager.selectedDevice {
                // 디바이스가 있으면 신호 정보 표시
                self.hasSignal = true
                self.signalInfo = self.formatSignalInfo(for: device)
            } else {
                // 디바이스가 없으면 "No Signal"
                self.hasSignal = false
                self.signalInfo = "No Signal"
            }
        }
    }

    /// 디바이스 정보를 포맷팅하여 반환
    private func formatSignalInfo(for device: AVCaptureDevice) -> String {
        // 현재 활성화된 포맷 가져오기
        let format = device.activeFormat
        let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)

        // 프레임레이트 가져오기
        let frameRate = Int(Int64(device.activeVideoMaxFrameDuration.timescale) / device.activeVideoMaxFrameDuration.value)

        return "\(dimensions.width)×\(dimensions.height) @ \(frameRate)fps"
    }

    /// 디바이스 새로고침
    func refreshDevices() {
        deviceManager.refreshDevices()
    }

    /// 디바이스 선택
    func selectDevice(_ device: AVCaptureDevice) {
        deviceManager.selectDevice(device)
    }
}
