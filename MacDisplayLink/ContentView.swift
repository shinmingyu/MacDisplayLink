//
//  ContentView.swift
//  MacDisplayLink
//
//  Created by 신민규 on 12/1/25.
//
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var deviceManager = CaptureDeviceManager()
    @StateObject private var sessionManager = VideoCaptureSessionManager()
    @StateObject private var audioManager = AudioCaptureManager()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Video Capture Devices")
                .font(.headline)

            if deviceManager.videoDevices.isEmpty {
                Text("No video capture devices found.")
                    .foregroundStyle(.secondary)
            } else {
                List(deviceManager.videoDevices, id: \.uniqueID) { device in
                    VStack(alignment: .leading) {
                        Text(device.localizedName)
                        Text(device.uniqueID)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Audio Capture")
                    .font(.headline)

                if audioManager.isRunning {
                    Text("Audio input active")
                        .foregroundStyle(.secondary)
                } else if let error = audioManager.lastError {
                    Text("Audio error: \(error)")
                        .foregroundStyle(.red)
                } else {
                    Text("Audio input stopped")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .onAppear {
            sessionManager.configureSession(with: deviceManager.videoDevices.first)
            sessionManager.startSession()
            audioManager.start()
        }
        .onChange(of: deviceManager.videoDevices.map(\.uniqueID)) { _, _ in
            sessionManager.configureSession(with: deviceManager.videoDevices.first)
            sessionManager.startSession()
        }
    }
}

#Preview {
    ContentView()
}
