//
//  MainView.swift
//  MacDisplayLink
//
//  Created by Claude on 12/21/25.
//

import SwiftUI

struct MainView: View {
    @StateObject private var settingsViewModel = SettingsViewModel()
    @StateObject private var recordingViewModel = RecordingViewModel()
    @StateObject private var deviceViewModel: DeviceViewModel

    @State private var showControls: Bool = true
    @State private var showSettings: Bool = false

    init() {
        let settingsVM = SettingsViewModel()
        let recordingVM = RecordingViewModel(settingsViewModel: settingsVM)

        _settingsViewModel = StateObject(wrappedValue: settingsVM)
        _recordingViewModel = StateObject(wrappedValue: recordingVM)
        _deviceViewModel = StateObject(wrappedValue: DeviceViewModel(recordingManager: recordingVM.getRecordingManager()))
    }

    var body: some View {
        ZStack {
            // PreviewView (배경)
            PreviewView(viewModel: deviceViewModel)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showControls.toggle()
                    }
                }

            // 디바이스 미연결 경고 배너
            if !deviceViewModel.isDeviceConnected {
                VStack {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.yellow)
                        Text("캡쳐 카드가 연결되지 않았습니다")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Spacer()
                    }
                    .padding()
                    .background(.red.opacity(0.8))
                    .cornerRadius(8)
                    .padding()

                    Spacer()
                }
            }

            // ControlsOverlay (컨트롤)
            if showControls {
                ControlsOverlay(
                    recordingViewModel: recordingViewModel,
                    deviceViewModel: deviceViewModel,
                    showSettings: $showSettings
                )
                .transition(.opacity)
            }
        }
        .frame(minWidth: 1280, minHeight: 720)
        .sheet(isPresented: $showSettings) {
            SettingsView(settingsViewModel: settingsViewModel, deviceViewModel: deviceViewModel)
        }
    }
}

#Preview {
    MainView()
}
