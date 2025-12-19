//
//  AudioCaptureManager.swift
//  MacDisplayLink
//
//  Created by Codex.
//

import AVFoundation
import Combine
import CoreMedia
import Foundation

final class AudioCaptureManager: NSObject, ObservableObject {
    let session = AVCaptureSession()

    @Published private(set) var isRunning = false
    @Published private(set) var lastError: String?
    @Published private(set) var lastAudioFormat: CMFormatDescription?

    private let audioOutput = AVCaptureAudioDataOutput()
    private let audioQueue = DispatchQueue(label: "AudioCaptureManager.queue")

    func start(with device: AVCaptureDevice? = AVCaptureDevice.default(for: .audio)) {
        session.stopRunning()
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        session.inputs.forEach { session.removeInput($0) }
        session.outputs.forEach { session.removeOutput($0) }

        guard let device else {
            isRunning = false
            lastError = "No audio capture device available."
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            guard session.canAddInput(input) else {
                isRunning = false
                lastError = "Unable to add audio device input."
                return
            }
            session.addInput(input)
        } catch {
            isRunning = false
            lastError = error.localizedDescription
            return
        }

        audioOutput.setSampleBufferDelegate(self, queue: audioQueue)
        guard session.canAddOutput(audioOutput) else {
            isRunning = false
            lastError = "Unable to add audio data output."
            return
        }
        session.addOutput(audioOutput)

        session.commitConfiguration()
        session.startRunning()

        isRunning = session.isRunning
        lastError = nil
    }

    func stop() {
        session.stopRunning()
        isRunning = false
    }
}

extension AudioCaptureManager: AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        if let format = CMSampleBufferGetFormatDescription(sampleBuffer) {
            DispatchQueue.main.async { [weak self] in
                self?.lastAudioFormat = format
            }
        }
    }
}
