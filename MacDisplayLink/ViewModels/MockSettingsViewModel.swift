//
//  MockSettingsViewModel.swift
//  MacDisplayLink
//
//  Created by Claude on 12/21/25.
//

import SwiftUI
import Combine

class MockSettingsViewModel: ObservableObject {
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
}
