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
        videoDevices = discoverySession.devices
    }
}
