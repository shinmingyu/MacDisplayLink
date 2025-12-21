//
//  RecordButton.swift
//  MacDisplayLink
//
//  Created by Claude on 12/21/25.
//

import SwiftUI

struct RecordButton: View {
    @ObservedObject var viewModel: MockRecordingViewModel

    @State private var isPulsing = false

    var body: some View {
        Button(action: {
            viewModel.toggleRecording()
        }) {
            ZStack {
                // 배경 원
                Circle()
                    .fill(Color.red.opacity(0.2))
                    .frame(width: 60, height: 60)

                // 녹화 아이콘
                if viewModel.isRecording {
                    // 녹화 중: 사각형 (정지 아이콘)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.red)
                        .frame(width: 24, height: 24)
                } else {
                    // 녹화 전: 원 (녹화 아이콘)
                    Circle()
                        .fill(Color.red)
                        .frame(width: 28, height: 28)
                }
            }
            .scaleEffect(isPulsing && viewModel.isRecording ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isPulsing)
        }
        .buttonStyle(.plain)
        .onChange(of: viewModel.isRecording) { _, isRecording in
            isPulsing = isRecording
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        RecordButton(viewModel: MockRecordingViewModel())
        Text("Click to toggle recording")
            .foregroundStyle(.secondary)
    }
    .padding()
}
