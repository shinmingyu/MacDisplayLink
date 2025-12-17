//
//  VideoCaptureSessionManager.swift
//  MacDisplayLink
//
//  Created by Codex.
//

import AVFoundation
import Combine
import Foundation

final class VideoCaptureSessionManager: ObservableObject {
    let session = AVCaptureSession()

    @Published private(set) var isConfigured = false
    @Published private(set) var configurationError: String?

    func configureSession(with device: AVCaptureDevice?) {
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        for input in session.inputs {
            session.removeInput(input)
        }

        guard let device else {
            isConfigured = false
            configurationError = "No capture device available."
            return
        }

        session.sessionPreset = .high

        do {
            let input = try AVCaptureDeviceInput(device: device)
            guard session.canAddInput(input) else {
                isConfigured = false
                configurationError = "Unable to add capture device input."
                return
            }
            session.addInput(input)
        } catch {
            isConfigured = false
            configurationError = error.localizedDescription
            return
        }

        isConfigured = true
        configurationError = nil
    }
}
