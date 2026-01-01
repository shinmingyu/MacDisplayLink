//
//  RecordingManager.swift
//  MacDisplayLink
//
//  Created by Claude on 12/30/25.
//

import AVFoundation
import Combine
import Foundation

/// 녹화 관리 서비스
/// AVAssetWriter를 통해 비디오/오디오 녹화 및 파일 저장
class RecordingManager: NSObject, ObservableObject {
    @Published var isRecording: Bool = false
    @Published var recordingDuration: TimeInterval = 0

    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var audioInput: AVAssetWriterInput?

    private var recordingStartTime: CMTime?
    private var recordingTimer: Timer?
    private var currentOutputURL: URL?

    // SettingsViewModel 참조
    private weak var settingsViewModel: SettingsViewModel?

    // 오디오 설정 (기본값) - Step 2.2에서 SettingsViewModel로 변경 예정
    private let defaultAudioBitrate: Int = 192_000 // 192 kbps
    private let defaultSampleRate: Double = 48000.0
    private let defaultChannels: Int = 2

    init(settingsViewModel: SettingsViewModel? = nil) {
        self.settingsViewModel = settingsViewModel
        super.init()
    }

    // MARK: - 파일 저장 경로

    /// 저장 폴더 경로 가져오기
    private func getRecordingsDirectory() -> URL {
        // App Sandbox 환경에서 Documents 디렉토리 사용
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let recordingsDirectory = documentsDirectory.appendingPathComponent("MacDisplayLink")

        // 폴더가 없으면 생성
        if !FileManager.default.fileExists(atPath: recordingsDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: recordingsDirectory, withIntermediateDirectories: true)
                print("📁 [RecordingManager] 녹화 폴더 생성: \(recordingsDirectory.path)")
            } catch {
                print("❌ [RecordingManager] 폴더 생성 실패: \(error.localizedDescription)")
            }
        }

        return recordingsDirectory
    }

    /// 녹화 파일 URL 생성
    private func generateRecordingURL() -> URL {
        let directory = getRecordingsDirectory()

        // 파일명 생성: MacDisplayLink_YYYYMMDD_HHMMSS.mp4
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        let filename = "MacDisplayLink_\(timestamp).mp4"

        let fileURL = directory.appendingPathComponent(filename)
        print("📝 [RecordingManager] 녹화 파일 경로: \(fileURL.path)")

        return fileURL
    }

    // MARK: - AVAssetWriter 설정

    /// AVAssetWriter 초기화
    private func setupAssetWriter(outputURL: URL) throws {
        // 기존 파일 삭제 (있으면)
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }

        // AVAssetWriter 생성
        assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)

        // 비디오 입력 설정
        setupVideoInput()

        // 오디오 입력 설정
        setupAudioInput()

        print("✅ [RecordingManager] AVAssetWriter 초기화 완료")
    }

    /// 비디오 입력 설정
    private func setupVideoInput() {
        // SettingsViewModel에서 설정값 가져오기 (없으면 기본값)
        let resolution = settingsViewModel?.getRecordingResolution() ?? (width: 1920, height: 1080)
        let frameRate = settingsViewModel?.frameRate ?? 60
        let videoBitrate = settingsViewModel?.getVideoBitrate() ?? 12_000_000

        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: resolution.width,
            AVVideoHeightKey: resolution.height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: videoBitrate,
                AVVideoExpectedSourceFrameRateKey: frameRate,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
            ]
        ]

        videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        videoInput?.expectsMediaDataInRealTime = true

        if let videoInput = videoInput, assetWriter?.canAdd(videoInput) == true {
            assetWriter?.add(videoInput)
            print("✅ [RecordingManager] 비디오 입력 추가 완료 - \(resolution.width)x\(resolution.height) @ \(frameRate)fps, \(videoBitrate/1000)kbps")
        }
    }

    /// 오디오 입력 설정
    private func setupAudioInput() {
        // SettingsViewModel에서 설정값 가져오기 (없으면 기본값)
        let audioBitrate = settingsViewModel?.getAudioBitrate() ?? defaultAudioBitrate

        let audioSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: defaultSampleRate,
            AVNumberOfChannelsKey: defaultChannels,
            AVEncoderBitRateKey: audioBitrate
        ]

        audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
        audioInput?.expectsMediaDataInRealTime = true

        if let audioInput = audioInput, assetWriter?.canAdd(audioInput) == true {
            assetWriter?.add(audioInput)
            print("✅ [RecordingManager] 오디오 입력 추가 완료 - \(audioBitrate/1000)kbps")
        }
    }

    // MARK: - 녹화 제어

    /// 녹화 시작
    func startRecording() {
        guard !isRecording else {
            print("⚠️ [RecordingManager] 이미 녹화 중입니다")
            return
        }

        do {
            // 출력 URL 생성
            let outputURL = generateRecordingURL()
            currentOutputURL = outputURL

            // AVAssetWriter 초기화
            try setupAssetWriter(outputURL: outputURL)

            // 녹화 시작
            guard let assetWriter = assetWriter else {
                throw RecordingError.assetWriterNotInitialized
            }

            assetWriter.startWriting()

            // 상태 업데이트
            DispatchQueue.main.async { [weak self] in
                self?.isRecording = true
                self?.recordingDuration = 0
                self?.startTimer()
            }

            print("▶️ [RecordingManager] 녹화 시작: \(outputURL.lastPathComponent)")

        } catch {
            print("❌ [RecordingManager] 녹화 시작 실패: \(error.localizedDescription)")
            DispatchQueue.main.async { [weak self] in
                self?.isRecording = false
            }
        }
    }

    /// 녹화 중지
    func stopRecording(completion: @escaping (URL?) -> Void) {
        guard isRecording else {
            print("⚠️ [RecordingManager] 녹화 중이 아닙니다")
            completion(nil)
            return
        }

        // 타이머 중지
        stopTimer()

        // 상태 업데이트
        DispatchQueue.main.async { [weak self] in
            self?.isRecording = false
        }

        // AVAssetWriter 완료 처리
        guard let assetWriter = assetWriter else {
            print("❌ [RecordingManager] AVAssetWriter가 없습니다")
            completion(nil)
            return
        }

        videoInput?.markAsFinished()
        audioInput?.markAsFinished()

        assetWriter.finishWriting { [weak self] in
            guard let self = self else {
                completion(nil)
                return
            }

            if assetWriter.status == .completed {
                print("✅ [RecordingManager] 녹화 완료: \(self.currentOutputURL?.lastPathComponent ?? "Unknown")")
                completion(self.currentOutputURL)
            } else {
                print("❌ [RecordingManager] 녹화 실패: \(assetWriter.error?.localizedDescription ?? "Unknown error")")
                completion(nil)
            }

            // 초기화
            self.assetWriter = nil
            self.videoInput = nil
            self.audioInput = nil
            self.recordingStartTime = nil
            self.currentOutputURL = nil
        }
    }

    // MARK: - 샘플 버퍼 쓰기

    /// 비디오 샘플 버퍼 추가
    func appendVideoSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard isRecording,
              let videoInput = videoInput,
              videoInput.isReadyForMoreMediaData else {
            return
        }

        // 녹화 시작 시간 설정 (최초 1회)
        if recordingStartTime == nil {
            let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            assetWriter?.startSession(atSourceTime: presentationTime)
            recordingStartTime = presentationTime
            print("🎬 [RecordingManager] 녹화 세션 시작: \(presentationTime.seconds)s")
        }

        // 비디오 샘플 추가
        if !videoInput.append(sampleBuffer) {
            print("⚠️ [RecordingManager] 비디오 샘플 추가 실패")
        }
    }

    /// 오디오 샘플 버퍼 추가
    func appendAudioSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard isRecording,
              recordingStartTime != nil, // 비디오가 시작된 후에만 오디오 추가
              let audioInput = audioInput,
              audioInput.isReadyForMoreMediaData else {
            return
        }

        // 오디오 샘플 추가
        if !audioInput.append(sampleBuffer) {
            print("⚠️ [RecordingManager] 오디오 샘플 추가 실패")
        }
    }

    // MARK: - 타이머

    /// 녹화 시간 타이머 시작
    private func startTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.recordingDuration += 1
            }
        }
    }

    /// 녹화 시간 타이머 중지
    private func stopTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
}

// MARK: - 에러 타입

enum RecordingError: Error {
    case assetWriterNotInitialized
    case failedToCreateDirectory

    var localizedDescription: String {
        switch self {
        case .assetWriterNotInitialized:
            return "AVAssetWriter가 초기화되지 않았습니다"
        case .failedToCreateDirectory:
            return "녹화 폴더 생성에 실패했습니다"
        }
    }
}
