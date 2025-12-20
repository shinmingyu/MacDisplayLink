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
    @Published private(set) var hasVideoSignal = false
    @Published private(set) var videoSignalInfo: String?

    private let videoOutput = AVCaptureVideoDataOutput()
    private let videoQueue = DispatchQueue(label: "VideoCaptureSessionManager.queue")
    var recordingManager: RecordingManager?

    func configureSession(with device: AVCaptureDevice?) {
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        session.inputs.forEach { session.removeInput($0) }
        session.outputs.forEach { session.removeOutput($0) }

        guard let device else {
            isConfigured = false
            configurationError = "No capture device available."
            hasVideoSignal = false
            videoSignalInfo = nil
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
            hasVideoSignal = false
            videoSignalInfo = nil
            return
        }
        session.addOutput(videoOutput)

        isConfigured = true
        configurationError = nil
        hasVideoSignal = false
        videoSignalInfo = nil
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
                self?.hasVideoSignal = true
                self?.videoSignalInfo = Self.describe(format: format, connection: connection)
            }
        }

        recordingManager?.appendVideoSample(sampleBuffer)
    }

    private static func describe(format: CMFormatDescription, connection: AVCaptureConnection) -> String {
        let dimensions = CMVideoFormatDescriptionGetDimensions(format)
        let fps: Double?
        let duration = connection.videoMinFrameDuration
        if duration.timescale > 0 && duration.value > 0 {
            fps = Double(duration.timescale) / Double(duration.value)
        } else {
            fps = nil
        }

        if let fps {
            return "\(dimensions.width)x\(dimensions.height) @ \(String(format: "%.2f", fps)) fps"
        } else {
            return "\(dimensions.width)x\(dimensions.height)"
        }
    }
}
