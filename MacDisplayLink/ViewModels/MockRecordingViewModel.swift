//
//  MockRecordingViewModel.swift
//  MacDisplayLink
//
//  Created by Claude on 12/21/25.
//

import SwiftUI
import Combine

class MockRecordingViewModel: ObservableObject {
    @Published var isRecording: Bool = false
    @Published var recordingTime: String = "00:00:00"

    private var timer: Timer?
    private var elapsedSeconds: Int = 0

    func toggleRecording() {
        isRecording.toggle()

        if isRecording {
            startRecording()
        } else {
            stopRecording()
        }
    }

    private func startRecording() {
        elapsedSeconds = 0
        updateTimeString()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.elapsedSeconds += 1
            self?.updateTimeString()
        }
    }

    private func stopRecording() {
        timer?.invalidate()
        timer = nil
        elapsedSeconds = 0
        recordingTime = "00:00:00"
    }

    private func updateTimeString() {
        let hours = elapsedSeconds / 3600
        let minutes = (elapsedSeconds % 3600) / 60
        let seconds = elapsedSeconds % 60
        recordingTime = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    deinit {
        timer?.invalidate()
    }
}
