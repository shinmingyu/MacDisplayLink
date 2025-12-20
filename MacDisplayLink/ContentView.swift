//
//  ContentView.swift
//  MacDisplayLink
//
//  Created by 신민규 on 12/1/25.
//
//

import AVFoundation
import SwiftUI
import AppKit

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
                    if sessionManager.availableFormats.isEmpty {
                        Text("No format info available")
                            .foregroundStyle(.secondary)
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Supported formats")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Picker("Format", selection: Binding(
                                get: { sessionManager.selectedFormatID ?? sessionManager.availableFormats.first?.id ?? "" },
                                set: { sessionManager.selectedFormatID = $0 }
                            )) {
                                ForEach(sessionManager.availableFormats) { option in
                                    Text(formatVideoOption(option))
                                        .tag(option.id)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }

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
                                get: { audioManager.displayVolume },
                                set: { audioManager.setVolumeFromUI($0) }
                            ),
                            in: 0...1
                        )
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(String(format: "%.0f%%", audioManager.displayVolume * 100))
                            Text(formatDb(from: audioManager.volume))
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 80, alignment: .trailing)
                        .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Level (avg)")
                        ProgressView(value: audioManager.meterLevel)
                            .frame(maxWidth: 160)
                        Text(String(format: "%.0f%%", audioManager.meterLevel * 100))
                            .frame(width: 60, alignment: .trailing)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Level (peak)")
                        ProgressView(value: audioManager.meterPeakLevel)
                            .frame(maxWidth: 160)
                        Text(String(format: "%.0f%%", audioManager.meterPeakLevel * 100))
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

                VStack(alignment: .leading, spacing: 4) {
                    Text("Save path")
                    HStack {
                        Text(outputDirectoryLabel())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                        Button("Choose folder") {
                            chooseOutputDirectory()
                        }
                    }
                }

                HStack {
                    Text("Format")
                    Picker("Format", selection: Binding(
                        get: { recordingManager.preferredFileType },
                        set: { recordingManager.setPreferredFileType($0) }
                    )) {
                        Text("MP4").tag(AVFileType.mp4)
                        Text("MOV").tag(AVFileType.mov)
                    }
                    .pickerStyle(.segmented)
                }
                HStack {
                    Text("Codec")
                    Picker("Codec", selection: Binding(
                        get: { recordingManager.preferredVideoCodec },
                        set: { recordingManager.setPreferredVideoCodec($0) }
                    )) {
                        Text("H.264").tag(AVVideoCodecType.h264)
                        Text("H.265").tag(AVVideoCodecType.hevc)
                    }
                    .pickerStyle(.segmented)
                }
                HStack {
                    Text("Bitrate")
                    Slider(
                        value: Binding(
                            get: { Double(recordingManager.preferredVideoBitrate) / 1_000_000 },
                            set: { recordingManager.setPreferredVideoBitrate(Int($0 * 1_000_000)) }
                        ),
                        in: 1...50,
                        step: 1
                    )
                    Text("\(recordingManager.preferredVideoBitrate / 1_000_000) Mbps")
                        .frame(width: 90, alignment: .trailing)
                        .foregroundStyle(.secondary)
                }

                if let output = recordingManager.outputURL {
                    Text("Output: \(output.lastPathComponent)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Duration")
                    Spacer()
                    Text(formatDuration(recordingManager.recordedDuration))
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("File size")
                    Spacer()
                    Text(formatBytes(recordingManager.recordedFileSize))
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
        .onChange(of: sessionManager.selectedFormatID) { _, _ in
            sessionManager.applySelectedFormat()
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite else { return "--:--" }
        let totalSeconds = Int(seconds.rounded())
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        guard bytes > 0 else { return "0 B" }
        let kb = Double(bytes) / 1024.0
        if kb < 1024 {
            return String(format: "%.1f KB", kb)
        }
        let mb = kb / 1024.0
        return String(format: "%.1f MB", mb)
    }

    private func formatVideoOption(_ option: VideoFormatOption) -> String {
        let dims = option.dimensions
        let fps = option.maxFrameRate
        if fps > 0 {
            return "\(dims.width)x\(dims.height) @ \(String(format: "%.0f", fps)) fps"
        } else {
            return "\(dims.width)x\(dims.height)"
        }
    }

    private func formatDb(from linear: Float) -> String {
        guard linear > 0 else { return "-inf dB" }
        let db = 20 * log10(Double(linear))
        return String(format: "%.1f dB", db)
    }

    private func chooseOutputDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = "Select"

        if panel.runModal() == .OK {
            recordingManager.setCustomOutputDirectory(panel.url)
        }
    }

    private func outputDirectoryLabel() -> String {
        if let custom = recordingManager.customOutputDirectory {
            return custom.path
        }
        // Reflect default directory path for clarity.
        let fm = FileManager.default
        let base = fm.urls(for: .moviesDirectory, in: .userDomainMask).first
            ?? fm.urls(for: .documentDirectory, in: .userDomainMask).first
        let defaultPath = base?.appendingPathComponent("MacDisplayLink", isDirectory: true).path
        return defaultPath ?? "Default directory not available"
    }
}

#Preview {
    ContentView()
}
