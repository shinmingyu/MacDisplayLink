//
//  SettingsViewModel.swift
//  MacDisplayLink
//
//  Created by Claude on 12/21/25.
//

import SwiftUI
import Combine

class SettingsViewModel: ObservableObject {
    // 입력 포맷 (캡처 디바이스에서 선택)
    @Published var selectedInputFormatId: String? = nil // nil = "자동" (디바이스 기본값)

    // 녹화 설정
    @Published var recordingResolution: String = "입력과 동일"
    @Published var frameRate: Int = 60
    @Published var videoBitrate: Int = 12000
    @Published var audioBitrate: Int = 192

    private let defaults = UserDefaults.standard

    init() {
        loadSettings()
    }

    func loadSettings() {
        selectedInputFormatId = defaults.string(forKey: "selectedInputFormatId")
        recordingResolution = defaults.string(forKey: "recordingResolution") ?? "입력과 동일"
        frameRate = defaults.integer(forKey: "frameRate") != 0 ? defaults.integer(forKey: "frameRate") : 60
        videoBitrate = defaults.integer(forKey: "videoBitrate") != 0 ? defaults.integer(forKey: "videoBitrate") : 12000
        audioBitrate = defaults.integer(forKey: "audioBitrate") != 0 ? defaults.integer(forKey: "audioBitrate") : 192
    }

    func saveSettings() {
        defaults.set(selectedInputFormatId, forKey: "selectedInputFormatId")
        defaults.set(recordingResolution, forKey: "recordingResolution")
        defaults.set(frameRate, forKey: "frameRate")
        defaults.set(videoBitrate, forKey: "videoBitrate")
        defaults.set(audioBitrate, forKey: "audioBitrate")
    }

    // MARK: - Helper Methods

    /// 녹화 해상도를 width, height로 변환
    /// - Parameter inputFormat: 현재 선택된 입력 포맷 (recordingResolution이 "입력과 동일"일 때 사용)
    func getRecordingResolution(inputFormat: VideoFormat? = nil) -> (width: Int, height: Int) {
        // "입력과 동일"이면 입력 포맷의 해상도 사용
        if recordingResolution == "입력과 동일", let format = inputFormat {
            return (format.width, format.height)
        }

        // 고정 해상도 사용
        switch recordingResolution {
        case "720p":
            return (1280, 720)
        case "1080p":
            return (1920, 1080)
        case "1440p":
            return (2560, 1440)
        case "4K":
            return (3840, 2160)
        default:
            // "입력과 동일"인데 inputFormat이 없으면 기본값
            return (1920, 1080)
        }
    }

    /// 비디오 비트레이트를 bps로 변환 (kbps → bps)
    func getVideoBitrate() -> Int {
        return videoBitrate * 1000
    }

    /// 오디오 비트레이트를 bps로 변환 (kbps → bps)
    func getAudioBitrate() -> Int {
        return audioBitrate * 1000
    }
}
