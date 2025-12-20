//
//  VideoCaptureSessionManager.swift
//  MacDisplayLink
//
//  Created by Codex.
//

import AVFoundation
import Combine
import Foundation
import AppKit

final class VideoCaptureSessionManager: NSObject, ObservableObject {
    let session = AVCaptureSession()

    @Published private(set) var isConfigured = false
    @Published private(set) var configurationError: String?
    @Published private(set) var lastVideoFormat: CMFormatDescription?
    @Published private(set) var hasVideoSignal = false
    @Published private(set) var videoSignalInfo: String?
    @Published private(set) var availableFormats: [VideoFormatOption] = []
    @Published var selectedFormatID: String?

    private let videoOutput = AVCaptureVideoDataOutput()
    private let videoQueue = DispatchQueue(label: "VideoCaptureSessionManager.queue")
    private let pixelBufferLock = DispatchQueue(label: "VideoCaptureSessionManager.pixelBuffer")
    private var latestPixelBuffer: CVPixelBuffer?
    var recordingManager: RecordingManager?
    private var currentDevice: AVCaptureDevice?

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
            availableFormats = []
            selectedFormatID = nil
            currentDevice = nil
            return
        }

        session.sessionPreset = .high
        availableFormats = Self.buildFormats(for: device)
        selectedFormatID = availableFormats.first?.id
        currentDevice = device

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

        if let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            pixelBufferLock.async { [weak self] in
                self?.latestPixelBuffer = buffer
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

    private static func buildFormats(for device: AVCaptureDevice) -> [VideoFormatOption] {
        device.formats.map { format in
            let desc = format.formatDescription
            let dims = CMVideoFormatDescriptionGetDimensions(desc)
            let frameRate = format.videoSupportedFrameRateRanges.max(by: { $0.maxFrameRate < $1.maxFrameRate })
            let maxFPS = frameRate?.maxFrameRate ?? 0
            return VideoFormatOption(
                id: Self.makeFormatID(description: desc, dimensions: dims, maxFPS: maxFPS),
                format: format,
                dimensions: dims,
                maxFrameRate: maxFPS
            )
        }
        .sorted { lhs, rhs in
            if lhs.dimensions.width == rhs.dimensions.width {
                return lhs.maxFrameRate > rhs.maxFrameRate
            }
            return lhs.dimensions.width > rhs.dimensions.width
        }
    }

    private static func makeFormatID(description: CMFormatDescription, dimensions: CMVideoDimensions, maxFPS: Double) -> String {
        let fourCC = CMFormatDescriptionGetMediaSubType(description)
        let c1 = Character(UnicodeScalar((fourCC >> 24) & 0xFF)!)
        let c2 = Character(UnicodeScalar((fourCC >> 16) & 0xFF)!)
        let c3 = Character(UnicodeScalar((fourCC >> 8) & 0xFF)!)
        let c4 = Character(UnicodeScalar(fourCC & 0xFF)!)
        let code = "\(c1)\(c2)\(c3)\(c4)"
        return "\(dimensions.width)x\(dimensions.height)-\(code)-\(Int(maxFPS))"
    }

    func applySelectedFormat() {
        guard let device = currentDevice,
              let selectedFormatID,
              let option = availableFormats.first(where: { $0.id == selectedFormatID })
        else { return }

        let wasRunning = session.isRunning
        session.beginConfiguration()
        if wasRunning { session.stopRunning() }

        do {
            try device.lockForConfiguration()
            device.activeFormat = option.format
            if option.maxFrameRate > 0 {
                let fps = max(1, Int32(option.maxFrameRate.rounded()))
                let duration = CMTime(value: 1, timescale: fps)
                device.activeVideoMinFrameDuration = duration
                device.activeVideoMaxFrameDuration = duration
            }
            device.unlockForConfiguration()
            configurationError = nil
        } catch {
            configurationError = "Failed to set format: \(error.localizedDescription)"
        }

        session.commitConfiguration()
        if wasRunning { session.startRunning() }
    }

    /// Captures the latest video frame as an NSImage. Returns nil if no frame is available yet.
    func captureScreenshotImage() -> NSImage? {
        var pixelBuffer: CVPixelBuffer?
        pixelBufferLock.sync {
            pixelBuffer = latestPixelBuffer
        }
        guard let buffer = pixelBuffer else { return nil }

        let ciImage = CIImage(cvPixelBuffer: buffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    }
}

struct VideoFormatOption: Identifiable, Hashable {
    let id: String
    let format: AVCaptureDevice.Format
    let dimensions: CMVideoDimensions
    let maxFrameRate: Double

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: VideoFormatOption, rhs: VideoFormatOption) -> Bool {
        lhs.id == rhs.id
    }
}
