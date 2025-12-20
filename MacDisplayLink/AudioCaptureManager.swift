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
    @Published private(set) var isMonitoring = false
    @Published private(set) var volume: Float = 1.0
    @Published private(set) var displayVolume: Float = 1.0
    @Published private(set) var meterLevel: Float = 0.0
    @Published private(set) var meterPeakLevel: Float = 0.0

    private let audioOutput = AVCaptureAudioDataOutput()
    private let audioQueue = DispatchQueue(label: "AudioCaptureManager.queue")
    private let rendererQueue = DispatchQueue(label: "AudioCaptureManager.renderer")
    private let audioRenderer = AVSampleBufferAudioRenderer()
    private var didRequestMediaData = false
    var recordingManager: RecordingManager?

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

        if !didRequestMediaData {
            audioRenderer.requestMediaDataWhenReady(on: rendererQueue) { }
            didRequestMediaData = true
        }
        rendererQueue.async { [weak self] in
            guard let self else { return }
            self.audioRenderer.volume = self.volume
        }

        isRunning = session.isRunning
        lastError = nil
        isMonitoring = true
    }

    func stop() {
        session.stopRunning()
        audioRenderer.stopRequestingMediaData()
        audioRenderer.flush()
        isRunning = false
        isMonitoring = false
    }

    /// Accepts a UI value (0...1) and maps it to a non-linear curve for finer low-volume control.
    func setVolumeFromUI(_ newValue: Float) {
        let clampedDisplay = max(0, min(1, newValue))
        displayVolume = clampedDisplay
        let curvedVolume = pow(clampedDisplay, 2.5) // more resolution near 0
        let finalVolume = max(0, min(1, curvedVolume))
        volume = finalVolume
        rendererQueue.async { [weak self] in
            self?.audioRenderer.volume = finalVolume
        }
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

        rendererQueue.async { [weak self] in
            guard let self else { return }
            guard self.audioRenderer.isReadyForMoreMediaData else { return }
            self.audioRenderer.enqueue(sampleBuffer)
        }

        updateMeter(sampleBuffer: sampleBuffer)
        recordingManager?.appendAudioSample(sampleBuffer)
    }

    private func updateMeter(sampleBuffer: CMSampleBuffer) {
        guard let formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer),
              let asbdPointer = CMAudioFormatDescriptionGetStreamBasicDescription(formatDesc) else { return }

        var asbd = asbdPointer.pointee
        guard let format = AVAudioFormat(streamDescription: &asbd) else { return }

        let frameCount = AVAudioFrameCount(CMSampleBufferGetNumSamples(sampleBuffer))
        guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        pcmBuffer.frameLength = frameCount

        let framesToCopy = Int32(min(frameCount, AVAudioFrameCount(Int32.max)))
        let status = CMSampleBufferCopyPCMDataIntoAudioBufferList(
            sampleBuffer,
            at: 0,
            frameCount: framesToCopy,
            into: pcmBuffer.mutableAudioBufferList
        )
        guard status == noErr else { return }

        let levels = computeLevels(pcmBuffer: pcmBuffer, format: asbd)
        DispatchQueue.main.async { [weak self] in
            self?.meterLevel = levels.rms
            self?.meterPeakLevel = levels.peak
        }
    }

    private func computeLevels(pcmBuffer: AVAudioPCMBuffer, format: AudioStreamBasicDescription) -> (rms: Float, peak: Float) {
        let isFloat = (format.mFormatFlags & kAudioFormatFlagIsFloat) != 0
        let audioBuffers = UnsafeMutableAudioBufferListPointer(pcmBuffer.mutableAudioBufferList)

        var total: Float = 0
        var processedSamples = 0
        var peak: Float = 0

        for buffer in audioBuffers {
            guard let dataPtr = buffer.mData else { continue }
            let byteCount = Int(buffer.mDataByteSize)

            if isFloat {
                let sampleCount = byteCount / MemoryLayout<Float>.size
                let floatPtr = dataPtr.assumingMemoryBound(to: Float.self)
                for i in 0..<sampleCount {
                    let sample = floatPtr[i]
                    total += sample * sample
                    peak = max(peak, abs(sample))
                }
                processedSamples += sampleCount
            } else {
                let sampleCount = byteCount / MemoryLayout<Int16>.size
                let int16Ptr = dataPtr.assumingMemoryBound(to: Int16.self)
                let scale: Float = 1.0 / 32768.0
                for i in 0..<sampleCount {
                    let sample = Float(int16Ptr[i]) * scale
                    total += sample * sample
                    peak = max(peak, abs(sample))
                }
                processedSamples += sampleCount
            }
        }

        guard processedSamples > 0 else { return (0, 0) }
        let rms = sqrt(total / Float(processedSamples))
        return (min(1.0, max(0.0, rms)), min(1.0, max(0.0, peak)))
    }
}
