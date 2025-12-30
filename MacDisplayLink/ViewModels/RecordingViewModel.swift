//
//  RecordingViewModel.swift
//  MacDisplayLink
//
//  Created by Claude on 12/30/25.
//

import SwiftUI
import Combine
import AVFoundation

/// 녹화 관리 ViewModel
/// RecordingManager를 통해 녹화 상태 관리
class RecordingViewModel: ObservableObject {
    @Published var isRecording: Bool = false
    @Published var recordingTime: String = "00:00:00"

    private let recordingManager: RecordingManager
    private var cancellables = Set<AnyCancellable>()

    init(recordingManager: RecordingManager = RecordingManager()) {
        self.recordingManager = recordingManager

        // RecordingManager의 녹화 상태 변경 감지
        recordingManager.$isRecording
            .sink { [weak self] isRecording in
                self?.isRecording = isRecording
            }
            .store(in: &cancellables)

        // RecordingManager의 녹화 시간 변경 감지
        recordingManager.$recordingDuration
            .sink { [weak self] duration in
                self?.recordingTime = self?.formatDuration(duration) ?? "00:00:00"
            }
            .store(in: &cancellables)
    }

    /// 녹화 시작/중지 토글
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    /// 녹화 시작
    private func startRecording() {
        print("🎬 [RecordingViewModel] 녹화 시작 요청")
        recordingManager.startRecording()
    }

    /// 녹화 중지
    private func stopRecording() {
        print("⏹ [RecordingViewModel] 녹화 중지 요청")
        recordingManager.stopRecording { [weak self] outputURL in
            if let outputURL = outputURL {
                print("✅ [RecordingViewModel] 녹화 완료: \(outputURL.lastPathComponent)")
                // TODO: 사용자에게 녹화 완료 알림 (Alert 또는 Notification)
            } else {
                print("❌ [RecordingViewModel] 녹화 실패")
                // TODO: 사용자에게 녹화 실패 알림
            }
        }
    }

    /// 녹화 시간 포맷팅 (HH:MM:SS)
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60

        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    /// RecordingManager 접근자 (CaptureSessionManager에서 샘플 버퍼 전달용)
    func getRecordingManager() -> RecordingManager {
        return recordingManager
    }
}
