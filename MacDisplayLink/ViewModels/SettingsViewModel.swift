//
//  SettingsViewModel.swift
//  MacDisplayLink
//
//  Created by Claude on 12/21/25.
//

import SwiftUI
import Combine

class SettingsViewModel: ObservableObject {
    @Published var inputResolution: String = "1080p"
    @Published var recordingResolution: String = "1080p"
    @Published var frameRate: Int = 60
    @Published var videoBitrate: Int = 12000
    @Published var audioBitrate: Int = 192

    private let defaults = UserDefaults.standard

    init() {
        loadSettings()
    }

    func loadSettings() {
        inputResolution = defaults.string(forKey: "inputResolution") ?? "1080p"
        recordingResolution = defaults.string(forKey: "recordingResolution") ?? "1080p"
        frameRate = defaults.integer(forKey: "frameRate") != 0 ? defaults.integer(forKey: "frameRate") : 60
        videoBitrate = defaults.integer(forKey: "videoBitrate") != 0 ? defaults.integer(forKey: "videoBitrate") : 12000
        audioBitrate = defaults.integer(forKey: "audioBitrate") != 0 ? defaults.integer(forKey: "audioBitrate") : 192
    }

    func saveSettings() {
        defaults.set(inputResolution, forKey: "inputResolution")
        defaults.set(recordingResolution, forKey: "recordingResolution")
        defaults.set(frameRate, forKey: "frameRate")
        defaults.set(videoBitrate, forKey: "videoBitrate")
        defaults.set(audioBitrate, forKey: "audioBitrate")
    }

    // MARK: - Helper Methods

    /// 녹화 해상도를 width, height로 변환
    func getRecordingResolution() -> (width: Int, height: Int) {
        let resolution = recordingResolution == "입력과 동일" ? inputResolution : recordingResolution

        switch resolution {
        case "720p":
            return (1280, 720)
        case "1080p":
            return (1920, 1080)
        case "1440p":
            return (2560, 1440)
        case "4K":
            return (3840, 2160)
        default:
            return (1920, 1080) // 기본값
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
