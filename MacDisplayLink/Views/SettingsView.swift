//
//  SettingsView.swift
//  MacDisplayLink
//
//  Created by Claude on 12/21/25.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settingsViewModel: SettingsViewModel
    @ObservedObject var deviceViewModel: DeviceViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        TabView {
            DeviceSettingsTab(deviceViewModel: deviceViewModel)
                .tabItem {
                    Label("디바이스", systemImage: "video.badge.checkmark")
                }

            VideoSettingsTab(viewModel: settingsViewModel, deviceViewModel: deviceViewModel)
                .tabItem {
                    Label("영상", systemImage: "video.fill")
                }

            AudioSettingsTab(viewModel: settingsViewModel, deviceViewModel: deviceViewModel)
                .tabItem {
                    Label("오디오", systemImage: "speaker.wave.2.fill")
                }

            StorageSettingsTab()
                .tabItem {
                    Label("저장", systemImage: "internaldrive.fill")
                }
        }
        .frame(width: 600, height: 500)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("완료") {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    SettingsView(settingsViewModel: SettingsViewModel(), deviceViewModel: DeviceViewModel())
}
