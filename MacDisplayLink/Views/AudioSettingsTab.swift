//
//  AudioSettingsTab.swift
//  MacDisplayLink
//
//  Created by Claude on 12/21/25.
//

import SwiftUI

struct AudioSettingsTab: View {
    @ObservedObject var viewModel: MockSettingsViewModel

    let audioBitrateOptions = [128, 192, 256, 320]

    var body: some View {
        Form {
            Section("오디오 입력") {
                HStack {
                    Text("오디오 소스")
                    Spacer()
                    Text("캡쳐 카드 (시뮬레이션)")
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
}

#Preview {
    AudioSettingsTab(viewModel: MockSettingsViewModel())
        .frame(width: 500, height: 400)
}
