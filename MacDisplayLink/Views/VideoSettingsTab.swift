//
//  VideoSettingsTab.swift
//  MacDisplayLink
//
//  Created by Claude on 12/21/25.
//

import SwiftUI

struct VideoSettingsTab: View {
    @ObservedObject var viewModel: SettingsViewModel
    @ObservedObject var deviceViewModel: DeviceViewModel

    let recordingResolutionOptions = ["720p", "1080p", "1440p", "4K"]
    let frameRateOptions = [30, 60, 120]

    var body: some View {
        Form {
            Section("입력 설정") {
                Picker("입력 포맷", selection: $viewModel.selectedInputFormatId) {
                    // "자동" 옵션
                    Text("자동 (디바이스 기본값)").tag(nil as String?)

                    // 사용 가능한 포맷 목록
                    ForEach(deviceViewModel.availableFormats, id: \.id) { format in
                        Text(format.displayName).tag(format.id as String?)
                    }
                }
                .onChange(of: viewModel.selectedInputFormatId) { _, newValue in
                    viewModel.saveSettings()
                    deviceViewModel.applyInputFormat(newValue)
                }
                .disabled(deviceViewModel.availableFormats.isEmpty)

                if deviceViewModel.availableFormats.isEmpty {
                    Text("캡처 디바이스를 연결하세요")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }

            Section("녹화 설정") {
                Picker("녹화 해상도", selection: $viewModel.recordingResolution) {
                    Text("입력과 동일").tag("입력과 동일")
                    ForEach(recordingResolutionOptions, id: \.self) { resolution in
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
    VideoSettingsTab(viewModel: SettingsViewModel(), deviceViewModel: DeviceViewModel())
        .frame(width: 500, height: 400)
}
