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
    @StateObject private var recordingManager = RecordingManager()

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
                Text("Video Preview")
                    .font(.headline)

                if sessionManager.isConfigured {
                    ZStack {
                        VideoPreviewView(session: sessionManager.session)
                            .frame(minHeight: 240)
                            .background(.black.opacity(0.1))
                            .cornerRadius(8)

                        if !sessionManager.hasVideoSignal {
                            Text("No video signal")
                                .font(.headline)
                                .padding()
                                .background(Color.black.opacity(0.6))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }

                    if let info = sessionManager.videoSignalInfo {
                        Text("Signal: \(info)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else if let error = sessionManager.configurationError {
                    Text("Video error: \(error)")
                        .foregroundStyle(.red)
                } else {
                    Text("No video session configured.")
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Audio Capture")
                    .font(.headline)

                if audioManager.isRunning {
                    Text("Audio input active")
                        .foregroundStyle(.secondary)
                    HStack {
                        Text("Volume")
                        Slider(
                            value: Binding(
                                get: { audioManager.volume },
                                set: { audioManager.setVolume($0) }
                            ),
                            in: 0...1
                        )
                        Text(String(format: "%.0f%%", audioManager.volume * 100))
                            .frame(width: 60, alignment: .trailing)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Level")
                        ProgressView(value: audioManager.meterLevel)
                            .frame(maxWidth: 160)
                        Text(String(format: "%.0f%%", audioManager.meterLevel * 100))
                            .frame(width: 60, alignment: .trailing)
                            .foregroundStyle(.secondary)
                    }
                } else if let error = audioManager.lastError {
                        Text("Audio error: \(error)")
                            .foregroundStyle(.red)
                } else {
                    Text("Audio input stopped")
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Recording")
                    .font(.headline)

                HStack {
                    Button(recordingManager.isRecording ? "Stop Recording" : "Start Recording") {
                        if recordingManager.isRecording {
                            recordingManager.stopRecording()
                        } else {
                            recordingManager.startNewRecording()
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    switch recordingManager.state {
                    case .idle:
                        Text("Idle").foregroundStyle(.secondary)
                    case .recording:
                        Text("Recording...").foregroundStyle(.green)
                    case .finishing:
                        Text("Finishing...").foregroundStyle(.secondary)
                    case .failed(let message):
                        Text("Failed: \(message)").foregroundStyle(.red)
                    }
                }

                if let output = recordingManager.outputURL {
                    Text("Output: \(output.lastPathComponent)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .onAppear {
            sessionManager.recordingManager = recordingManager
            audioManager.recordingManager = recordingManager
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
