//
//  CaptureDeviceManager.swift
//  MacDisplayLink
//
//  Created by Codex.
//

import AVFoundation
import Combine
import Foundation

final class CaptureDeviceManager: ObservableObject {
    @Published private(set) var videoDevices: [AVCaptureDevice] = []

    init() {
        refreshVideoDevices()
    }

    func refreshVideoDevices() {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .external],
            mediaType: .video,
            position: .unspecified
        )
        videoDevices = discoverySession.devices.filter { !isBuiltInCamera($0) }
    }

    private func isBuiltInCamera(_ device: AVCaptureDevice) -> Bool {
        #if os(macOS)
        return device.deviceType == .builtInWideAngleCamera
        #else
        switch device.deviceType {
        case .builtInWideAngleCamera,
             .builtInUltraWideCamera,
             .builtInTelephotoCamera,
             .builtInDualCamera,
             .builtInDualWideCamera,
             .builtInTripleCamera,
             .builtInTrueDepthCamera:
            return true
        default:
            return false
        }
        #endif
    }
}
