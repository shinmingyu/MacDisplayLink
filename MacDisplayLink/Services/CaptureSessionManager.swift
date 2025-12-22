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

/// 비디오 캡쳐 세션 관리 서비스
/// AVCaptureSession을 통해 실시간 비디오 프레임 캡쳐
class CaptureSessionManager: NSObject, ObservableObject {
    @Published var currentFrame: CGImage?
    @Published var hasSignal: Bool = false
    @Published var signalInfo: String = "No Signal"

    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let videoQueue = DispatchQueue(label: "com.echo.MacDisplayLink.videoQueue")
    private let ciContext = CIContext()

    private var currentDevice: AVCaptureDevice?

    override init() {
        super.init()
        setupVideoOutput()
    }

    /// 비디오 출력 설정
    private func setupVideoOutput() {
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true // 지연 프레임 버림

        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
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
                // 새 디바이스 입력 추가
                let input = try AVCaptureDeviceInput(device: device)
                if self.captureSession.canAddInput(input) {
                    self.captureSession.addInput(input)
                    self.currentDevice = device
                    print("✅ [CaptureSession] 디바이스 입력 추가: \(device.localizedName)")
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

    /// 세션 중지
    func stopSession() {
        videoQueue.async { [weak self] in
            guard let self = self else { return }

            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
                print("⏸ [CaptureSession] 세션 중지")
            }

            DispatchQueue.main.async {
                self.hasSignal = false
                self.currentFrame = nil
                self.signalInfo = "No Signal"
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
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CaptureSessionManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // 프레임 수신 시 신호 정보 업데이트 (최초 1회)
        if !hasSignal {
            updateSignalInfo()
        }

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
}
