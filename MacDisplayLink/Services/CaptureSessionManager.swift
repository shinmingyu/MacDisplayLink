//
//  CaptureSessionManager.swift
//  MacDisplayLink
//
//  Created by Claude on 12/22/25.
//

import AVFoundation
import Combine
import CoreImage
import SwiftUI
import Accelerate

/// 비디오/오디오 캡쳐 세션 관리 서비스
/// AVCaptureSession을 통해 실시간 비디오 프레임 및 오디오 캡쳐
class CaptureSessionManager: NSObject, ObservableObject {
    @Published var currentFrame: CGImage?
    @Published var hasSignal: Bool = false
    @Published var signalInfo: String = "No Signal"
    @Published var audioLevel: Float = 0.0
    @Published var isMuted: Bool = false
    @Published var hasAudioSignal: Bool = false

    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let audioOutput = AVCaptureAudioDataOutput()
    private let audioPreviewOutput = AVCaptureAudioPreviewOutput()
    private let videoQueue = DispatchQueue(label: "com.echo.MacDisplayLink.videoQueue")
    private let audioQueue = DispatchQueue(label: "com.echo.MacDisplayLink.audioQueue")
    private let ciContext = CIContext()

    private var currentDevice: AVCaptureDevice?
    private var audioLevelLogCount = 0
    private var smoothedAudioLevel: Float = 0.0
    private weak var recordingManager: RecordingManager?

    init(recordingManager: RecordingManager? = nil) {
        self.recordingManager = recordingManager
        super.init()
        setupVideoOutput()
        setupAudioOutput()
        setupAudioPreviewOutput()
    }

    /// 비디오 출력 설정
    private func setupVideoOutput() {
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true // 지연 프레임 버림

        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
    }

    /// 오디오 출력 설정 (레벨 측정용)
    private func setupAudioOutput() {
        audioOutput.setSampleBufferDelegate(self, queue: audioQueue)

        if captureSession.canAddOutput(audioOutput) {
            captureSession.addOutput(audioOutput)
        }
    }

    /// 오디오 프리뷰 출력 설정 (재생용)
    private func setupAudioPreviewOutput() {
        // 기본 볼륨 설정
        audioPreviewOutput.volume = 1.0

        if captureSession.canAddOutput(audioPreviewOutput) {
            captureSession.addOutput(audioPreviewOutput)
        }
    }

    /// 디바이스로 세션 구성
    func configureSession(with device: AVCaptureDevice) {
        videoQueue.async { [weak self] in
            guard let self = self else { return }

            // 기존 세션 정리
            self.captureSession.beginConfiguration()

            // 기존 입력 제거
            self.captureSession.inputs.forEach { input in
                self.captureSession.removeInput(input)
            }

            do {
                // 비디오 입력 추가
                let videoInput = try AVCaptureDeviceInput(device: device)
                if self.captureSession.canAddInput(videoInput) {
                    self.captureSession.addInput(videoInput)
                    self.currentDevice = device
                    print("✅ [CaptureSession] 비디오 입력 추가: \(device.localizedName)")
                }

                // 오디오 입력 추가 (같은 디바이스에서 오디오 찾기)
                if let audioDevice = self.findAudioDevice(for: device) {
                    let audioInput = try AVCaptureDeviceInput(device: audioDevice)
                    if self.captureSession.canAddInput(audioInput) {
                        self.captureSession.addInput(audioInput)
                        print("✅ [CaptureSession] 오디오 입력 추가: \(audioDevice.localizedName)")
                    }
                } else {
                    print("⚠️ [CaptureSession] 오디오 디바이스를 찾을 수 없음")
                }
            } catch {
                print("❌ [CaptureSession] 디바이스 입력 추가 실패: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.hasSignal = false
                    self.signalInfo = "Error: \(error.localizedDescription)"
                }
            }

            self.captureSession.commitConfiguration()

            // 세션 시작
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
                print("▶️ [CaptureSession] 세션 시작")
            }
        }
    }

    /// 비디오 디바이스에 대응하는 오디오 디바이스 찾기
    private func findAudioDevice(for videoDevice: AVCaptureDevice) -> AVCaptureDevice? {
        // 모든 오디오 디바이스 검색
        let deviceTypes: [AVCaptureDevice.DeviceType]
        if #available(macOS 14.0, *) {
            deviceTypes = [.external, .microphone]
        } else {
            deviceTypes = [.externalUnknown, .builtInMicrophone]
        }

        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: deviceTypes,
            mediaType: .audio,
            position: .unspecified
        )

        // 비디오 디바이스와 이름이 유사한 오디오 디바이스 찾기
        for audioDevice in discoverySession.devices {
            print("  🔍 오디오 디바이스 발견: \(audioDevice.localizedName)")

            // 같은 제조사/모델명을 포함하는 오디오 디바이스 찾기
            if audioDevice.localizedName.contains(videoDevice.localizedName) ||
               videoDevice.localizedName.contains(audioDevice.localizedName) ||
               audioDevice.uniqueID.contains(videoDevice.uniqueID.prefix(10)) {
                print("  ✅ 매칭된 오디오 디바이스: \(audioDevice.localizedName)")
                return audioDevice
            }
        }

        // 매칭 실패 시 첫 번째 외부 오디오 디바이스 반환
        let externalAudioDevice = discoverySession.devices.first { device in
            !device.localizedName.lowercased().contains("built-in")
        }

        if let device = externalAudioDevice {
            print("  ⚠️ 첫 번째 외부 오디오 디바이스 사용: \(device.localizedName)")
        }

        return externalAudioDevice
    }

    /// 세션 중지
    func stopSession() {
        videoQueue.async { [weak self] in
            guard let self = self else { return }

            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
                print("⏸ [CaptureSession] 세션 중지")
            }

            // 스무딩 레벨 리셋
            self.smoothedAudioLevel = 0.0

            DispatchQueue.main.async {
                self.hasSignal = false
                self.hasAudioSignal = false
                self.currentFrame = nil
                self.signalInfo = "No Signal"
                self.audioLevel = 0.0
            }
        }
    }

    /// 신호 정보 업데이트
    private func updateSignalInfo() {
        guard let device = currentDevice else {
            DispatchQueue.main.async { [weak self] in
                self?.signalInfo = "No Signal"
                self?.hasSignal = false
            }
            return
        }

        let format = device.activeFormat
        let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
        let frameRate = Int(Int64(device.activeVideoMaxFrameDuration.timescale) / device.activeVideoMaxFrameDuration.value)

        let info = "\(dimensions.width)×\(dimensions.height) @ \(frameRate)fps"

        DispatchQueue.main.async { [weak self] in
            self?.signalInfo = info
            self?.hasSignal = true
        }
    }

    /// RMS 오디오 레벨 계산
    private func calculateAudioLevel(from sampleBuffer: CMSampleBuffer) -> Float {
        // CMBlockBuffer 직접 접근 방식
        guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else {
            if audioLevelLogCount < 3 {
                print("⚠️ [AudioLevel] CMBlockBuffer 없음")
                audioLevelLogCount += 1
            }
            return 0.0
        }

        var totalLength: Int = 0
        var dataPointer: UnsafeMutablePointer<Int8>?

        let status = CMBlockBufferGetDataPointer(
            blockBuffer,
            atOffset: 0,
            lengthAtOffsetOut: nil,
            totalLengthOut: &totalLength,
            dataPointerOut: &dataPointer
        )

        guard status == kCMBlockBufferNoErr,
              let pointer = dataPointer,
              totalLength > 0 else {
            if audioLevelLogCount < 3 {
                print("⚠️ [AudioLevel] 데이터 포인터 실패: \(status)")
                audioLevelLogCount += 1
            }
            return 0.0
        }

        // formatDescription에서 오디오 포맷 확인
        guard let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) else {
            return 0.0
        }

        let streamDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription)
        guard let asbd = streamDescription?.pointee else {
            return 0.0
        }

        let bytesPerSample = Int(asbd.mBitsPerChannel / 8)
        let sampleCount = totalLength / bytesPerSample

        guard sampleCount > 0 else {
            return 0.0
        }

        // 디버깅: 최초 1회 포맷 정보 출력
        if audioLevelLogCount == 0 {
            print("🎚 [AudioFormat] SampleRate: \(asbd.mSampleRate), Channels: \(asbd.mChannelsPerFrame), BitsPerChannel: \(asbd.mBitsPerChannel)")
        }

        // Int16 또는 Float32 처리
        var rms: Float = 0.0

        if bytesPerSample == 2 { // Int16
            let samples = UnsafeBufferPointer<Int16>(
                start: UnsafeRawPointer(pointer).assumingMemoryBound(to: Int16.self),
                count: sampleCount
            )

            var sum: Float = 0.0
            var maxSample: Int16 = 0
            for sample in samples {
                let normalized = Float(sample) / Float(Int16.max)
                sum += normalized * normalized
                maxSample = max(maxSample, abs(sample))
            }

            rms = sqrt(sum / Float(samples.count))

            if audioLevelLogCount < 5 {
                print("🎚 [AudioLevel] Int16 - MaxSample: \(maxSample), RMS: \(rms)")
            }
        } else if bytesPerSample == 4 { // Float32
            let samples = UnsafeBufferPointer<Float>(
                start: UnsafeRawPointer(pointer).assumingMemoryBound(to: Float.self),
                count: sampleCount
            )

            var sum: Float = 0.0
            var maxSample: Float = 0.0
            for sample in samples {
                sum += sample * sample
                maxSample = max(maxSample, abs(sample))
            }

            rms = sqrt(sum / Float(samples.count))

            if audioLevelLogCount < 5 {
                print("🎚 [AudioLevel] Float32 - MaxSample: \(maxSample), RMS: \(rms)")
            }

            // Float32가 정규화되지 않은 경우 (maxSample > 1.0) 정규화
            if maxSample > 1.0 {
                rms = rms / maxSample
                if audioLevelLogCount < 5 {
                    print("🎚 [AudioLevel] Float32 정규화됨 - 조정된 RMS: \(rms)")
                }
            }
        } else {
            if audioLevelLogCount < 3 {
                print("⚠️ [AudioLevel] 지원하지 않는 샘플 크기: \(bytesPerSample)")
            }
            return 0.0
        }

        if audioLevelLogCount < 5 {
            audioLevelLogCount += 1
        }

        // 0.0 ~ 1.0 범위로 정규화
        guard rms > 0.00001 else { // 매우 작은 값은 0으로 처리
            return 0.0
        }

        // RMS를 dB로 변환 후 0.0~1.0 범위로 매핑
        let decibels = 20 * log10(rms)

        // -60dB ~ 0dB 범위를 0.0~1.0으로 매핑 (더 넓은 다이나믹 레인지)
        let normalizedLevel = max(0.0, min(1.0, (decibels + 60) / 60))

        return normalizedLevel
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate & AVCaptureAudioDataOutputSampleBufferDelegate

extension CaptureSessionManager: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // 비디오 출력인지 오디오 출력인지 구분
        if output == videoOutput {
            handleVideoOutput(sampleBuffer)
        } else if output == audioOutput {
            handleAudioOutput(sampleBuffer)
        }
    }

    /// 비디오 출력 처리
    private func handleVideoOutput(_ sampleBuffer: CMSampleBuffer) {
        // 프레임 수신 시 신호 정보 업데이트 (최초 1회)
        if !hasSignal {
            updateSignalInfo()
        }

        // RecordingManager에 샘플 버퍼 전달 (녹화 중이면)
        recordingManager?.appendVideoSampleBuffer(sampleBuffer)

        // CVPixelBuffer 추출
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        // CIImage로 변환
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        // CGImage로 변환
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else {
            return
        }

        // 메인 스레드에서 UI 업데이트
        DispatchQueue.main.async { [weak self] in
            self?.currentFrame = cgImage
        }
    }

    /// 오디오 출력 처리
    private func handleAudioOutput(_ sampleBuffer: CMSampleBuffer) {
        // 오디오 신호 확인 (최초 1회)
        if !hasAudioSignal {
            DispatchQueue.main.async { [weak self] in
                self?.hasAudioSignal = true
                print("🎤 [CaptureSession] 오디오 신호 감지")
            }
        }

        // 비디오 신호가 없으면 오디오 레벨을 0으로 처리 (노이즈 방지)
        guard hasSignal else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.audioPreviewOutput.volume = 0.0  // 신호 없을 때 음소거
                self.audioLevel = 0.0
                self.smoothedAudioLevel = 0.0  // 스무딩 레벨도 리셋
            }
            return
        }

        // RecordingManager에 샘플 버퍼 전달 (녹화 중이면)
        recordingManager?.appendAudioSampleBuffer(sampleBuffer)

        // 오디오 레벨 계산 (원본)
        let rawLevel = calculateAudioLevel(from: sampleBuffer)

        // 스무딩 적용 (Exponential Moving Average)
        // smoothingFactor: 0.2 = 부드러움 (느린 반응), 0.5 = 중간, 0.8 = 빠른 반응
        let smoothingFactor: Float = 0.3
        smoothedAudioLevel = smoothedAudioLevel * (1 - smoothingFactor) + rawLevel * smoothingFactor

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // 음소거 상태에 따라 프리뷰 볼륨 조절
            self.audioPreviewOutput.volume = self.isMuted ? 0.0 : 1.0

            // UI에 스무딩된 레벨 표시
            self.audioLevel = self.smoothedAudioLevel
        }
    }
}
