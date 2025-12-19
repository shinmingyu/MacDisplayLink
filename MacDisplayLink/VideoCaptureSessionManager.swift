//
//  VideoCaptureSessionManager.swift
//  MacDisplayLink
//
//  Created by Codex.
//

import AVFoundation
import Combine
import Foundation

final class VideoCaptureSessionManager: NSObject, ObservableObject {
    let session = AVCaptureSession()

    @Published private(set) var isConfigured = false
    @Published private(set) var configurationError: String?
    @Published private(set) var lastVideoFormat: CMFormatDescription?

    private let videoOutput = AVCaptureVideoDataOutput()
    private let videoQueue = DispatchQueue(label: "VideoCaptureSessionManager.queue")

    func configureSession(with device: AVCaptureDevice?) {
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        session.inputs.forEach { session.removeInput($0) }
        session.outputs.forEach { session.removeOutput($0) }

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

        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true

        guard session.canAddOutput(videoOutput) else {
            isConfigured = false
            configurationError = "Unable to add video data output."
            return
        }
        session.addOutput(videoOutput)

        isConfigured = true
        configurationError = nil
    }

    func startSession() {
        guard isConfigured, !session.isRunning else { return }
        session.startRunning()
    }

    func stopSession() {
        guard session.isRunning else { return }
        session.stopRunning()
    }
}

extension VideoCaptureSessionManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        if let format = CMSampleBufferGetFormatDescription(sampleBuffer) {
            DispatchQueue.main.async { [weak self] in
                self?.lastVideoFormat = format
            }
        }
    }
}
