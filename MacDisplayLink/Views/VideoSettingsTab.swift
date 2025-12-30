//
//  VideoSettingsTab.swift
//  MacDisplayLink
//
//  Created by Claude on 12/21/25.
//

import SwiftUI

struct VideoSettingsTab: View {
    @ObservedObject var viewModel: SettingsViewModel

    let resolutionOptions = ["자동", "720p", "1080p", "1440p", "4K"]
    let frameRateOptions = [30, 60, 120]

    var body: some View {
        Form {
            Section("입력 설정") {
                Picker("입력 해상도", selection: $viewModel.inputResolution) {
                    ForEach(resolutionOptions, id: \.self) { resolution in
                        Text(resolution).tag(resolution)
                    }
                }
                .onChange(of: viewModel.inputResolution) { _, _ in
                    viewModel.saveSettings()
                }
            }

            Section("녹화 설정") {
                Picker("녹화 해상도", selection: $viewModel.recordingResolution) {
                    Text("입력과 동일").tag("입력과 동일")
                    ForEach(resolutionOptions.dropFirst(), id: \.self) { resolution in
                        Text(resolution).tag(resolution)
                    }
                }
                .onChange(of: viewModel.recordingResolution) { _, _ in
                    viewModel.saveSettings()
                }

                Picker("프레임레이트", selection: $viewModel.frameRate) {
                    ForEach(frameRateOptions, id: \.self) { fps in
                        Text("\(fps)fps").tag(fps)
                    }
                }
                .onChange(of: viewModel.frameRate) { _, _ in
                    viewModel.saveSettings()
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("비디오 비트레이트")
                        Spacer()
                        Text("\(viewModel.videoBitrate) kbps")
                            .foregroundStyle(.secondary)
                    }

                    Slider(value: Binding(
                        get: { Double(viewModel.videoBitrate) },
                        set: { viewModel.videoBitrate = Int($0) }
                    ), in: 5000...20000, step: 1000)
                    .onChange(of: viewModel.videoBitrate) { _, _ in
                        viewModel.saveSettings()
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    VideoSettingsTab(viewModel: SettingsViewModel())
        .frame(width: 500, height: 400)
}
