//
//  AudioSettingsTab.swift
//  MacDisplayLink
//
//  Created by Claude on 12/21/25.
//

import SwiftUI
import AVFoundation

struct AudioSettingsTab: View {
    @ObservedObject var viewModel: SettingsViewModel
    @ObservedObject var deviceViewModel: DeviceViewModel

    let audioBitrateOptions = [128, 192, 256, 320]

    var body: some View {
        Form {
            Section("오디오 입력") {
                HStack {
                    Text("오디오 소스")
                    Spacer()
                    Text(audioSourceName)
                        .foregroundStyle(.secondary)
                }
            }

            Section("녹화 설정") {
                Picker("오디오 비트레이트", selection: $viewModel.audioBitrate) {
                    ForEach(audioBitrateOptions, id: \.self) { bitrate in
                        Text("\(bitrate) kbps").tag(bitrate)
                    }
                }
                .onChange(of: viewModel.audioBitrate) { _, _ in
                    viewModel.saveSettings()
                }
            }
        }
        .formStyle(.grouped)
    }

    /// 오디오 소스 이름
    private var audioSourceName: String {
        if let device = deviceViewModel.selectedDevice {
            return device.localizedName
        } else {
            return "연결된 디바이스 없음"
        }
    }
}

#Preview {
    AudioSettingsTab(viewModel: SettingsViewModel(), deviceViewModel: DeviceViewModel())
        .frame(width: 500, height: 400)
}
