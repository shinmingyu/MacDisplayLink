//
//  RecordingManager.swift
//  MacDisplayLink
//
//  Created by Codex.
//

import AVFoundation
import Combine
import Foundation

final class RecordingManager: ObservableObject {
    enum State {
        case idle
        case recording
        case finishing
        case failed(String)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var outputURL: URL?

    private let queue = DispatchQueue(label: "RecordingManager.queue")
    private var writer: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var audioInput: AVAssetWriterInput?
    private var startTime: CMTime?

    func startRecording(to url: URL, fileType: AVFileType = .mp4) {
        queue.async { [weak self] in
            guard let self else { return }
            guard case .idle = self.state else { return }

            try? FileManager.default.removeItem(at: url)

            do {
                let writer = try AVAssetWriter(outputURL: url, fileType: fileType)
                self.writer = writer
                self.outputURL = url
                self.videoInput = nil
                self.audioInput = nil
                self.startTime = nil
                DispatchQueue.main.async { self.state = .recording }
            } catch {
                DispatchQueue.main.async { self.state = .failed(error.localizedDescription) }
            }
        }
    }

    func stopRecording() {
        queue.async { [weak self] in
            guard let self else { return }
            guard let writer = self.writer else { return }
            guard case .recording = self.state else { return }

            DispatchQueue.main.async { self.state = .finishing }
            self.videoInput?.markAsFinished()
            self.audioInput?.markAsFinished()

            writer.finishWriting { [weak self] in
                guard let self else { return }
                let resultState: State
                if writer.status == .failed {
                    resultState = .failed(writer.error?.localizedDescription ?? "Recording failed.")
                } else {
                    resultState = .idle
                }
                self.writer = nil
                self.videoInput = nil
                self.audioInput = nil
                self.startTime = nil
                DispatchQueue.main.async {
                    self.state = resultState
                }
            }
        }
    }

    func appendVideoSample(_ sampleBuffer: CMSampleBuffer) {
        queue.async { [weak self] in
            guard let self else { return }
            guard let writer = self.writer else { return }
            guard case .recording = self.state else { return }

            if self.videoInput == nil,
               let format = CMSampleBufferGetFormatDescription(sampleBuffer),
               let input = self.makeVideoInput(format: format),
               writer.canAdd(input) {
                writer.add(input)
                self.videoInput = input
            }

            guard let videoInput = self.videoInput, videoInput.isReadyForMoreMediaData else { return }

            let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            self.startSessionIfNeeded(with: timestamp)
            if writer.status == .writing {
                videoInput.append(sampleBuffer)
            }
        }
    }

    func appendAudioSample(_ sampleBuffer: CMSampleBuffer) {
        queue.async { [weak self] in
            guard let self else { return }
            guard let writer = self.writer else { return }
            guard case .recording = self.state else { return }

            if self.audioInput == nil,
               let format = CMSampleBufferGetFormatDescription(sampleBuffer),
               let input = self.makeAudioInput(format: format),
               writer.canAdd(input) {
                writer.add(input)
                self.audioInput = input
            }

            guard let audioInput = self.audioInput, audioInput.isReadyForMoreMediaData else { return }

            let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            self.startSessionIfNeeded(with: timestamp)
            if writer.status == .writing {
                audioInput.append(sampleBuffer)
            }
        }
    }

    private func startSessionIfNeeded(with timestamp: CMTime) {
        guard let writer = writer else { return }
        guard writer.status == .unknown else { return }

        writer.startWriting()
        writer.startSession(atSourceTime: timestamp)
        startTime = timestamp
    }

    private func makeVideoInput(format: CMFormatDescription) -> AVAssetWriterInput? {
        let dimensions = CMVideoFormatDescriptionGetDimensions(format)
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Int(dimensions.width),
            AVVideoHeightKey: Int(dimensions.height)
        ]
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        input.expectsMediaDataInRealTime = true
        return input
    }

    private func makeAudioInput(format: CMFormatDescription) -> AVAssetWriterInput? {
        guard let asbdPointer = CMAudioFormatDescriptionGetStreamBasicDescription(format) else { return nil }
        let asbd = asbdPointer.pointee
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVNumberOfChannelsKey: Int(asbd.mChannelsPerFrame),
            AVSampleRateKey: asbd.mSampleRate,
            AVEncoderBitRateKey: 128_000
        ]
        let input = AVAssetWriterInput(mediaType: .audio, outputSettings: settings)
        input.expectsMediaDataInRealTime = true
        return input
    }
}
