//
//  MainView.swift
//  MacDisplayLink
//
//  Created by Claude on 12/21/25.
//

import SwiftUI

struct MainView: View {
    @StateObject private var previewViewModel = MockPreviewViewModel()
    @StateObject private var recordingViewModel = MockRecordingViewModel()
    @StateObject private var audioViewModel = MockAudioViewModel()

    @State private var showControls: Bool = true
    @State private var showSettings: Bool = false

    var body: some View {
        ZStack {
            // PreviewView (배경)
            PreviewView(viewModel: previewViewModel)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showControls.toggle()
                    }
                }

            // ControlsOverlay (컨트롤)
            if showControls {
                ControlsOverlay(
                    recordingViewModel: recordingViewModel,
                    audioViewModel: audioViewModel,
                    showSettings: $showSettings
                )
                .transition(.opacity)
            }
        }
        .frame(minWidth: 1280, minHeight: 720)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}

#Preview {
    MainView()
}
