//
//  ControlsOverlay.swift
//  MacDisplayLink
//
//  Created by Claude on 12/21/25.
//

import SwiftUI

struct ControlsOverlay: View {
    @ObservedObject var recordingViewModel: MockRecordingViewModel
    @ObservedObject var deviceViewModel: DeviceViewModel
    @Binding var showSettings: Bool

    var body: some View {
        ZStack {
            // 반투명 배경 (클릭 무시)
            Color.black.opacity(0.3)
                .allowsHitTesting(false)

            VStack {
                // 상단: 설정 버튼
                HStack {
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(12)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
                .padding()

                Spacer()

                // 하단: 오디오 레벨 + 녹화 버튼 + 녹화 시간
                HStack(spacing: 32) {
                    // 왼쪽: 오디오 레벨
                    AudioLevelView(viewModel: deviceViewModel)

                    Spacer()

                    // 중앙: 녹화 버튼
                    RecordButton(viewModel: recordingViewModel)

                    Spacer()

                    // 오른쪽: 녹화 시간
                    Text(recordingViewModel.recordingTime)
                        .font(.system(.title3, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.9))
                        .frame(minWidth: 120)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
            }
        }
    }
}

#Preview {
    ControlsOverlay(
        recordingViewModel: MockRecordingViewModel(),
        deviceViewModel: DeviceViewModel(),
        showSettings: .constant(false)
    )
    .frame(width: 1280, height: 720)
}
