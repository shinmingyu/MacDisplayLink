//
//  AudioLevelView.swift
//  MacDisplayLink
//
//  Created by Claude on 12/21/25.
//

import SwiftUI

struct AudioLevelView: View {
    @ObservedObject var viewModel: DeviceViewModel

    var body: some View {
        HStack(spacing: 8) {
            // 스피커 아이콘
            Image(systemName: audioIcon)
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 20)

            // 레벨 바
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 배경
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.2))

                    // 레벨 표시
                    RoundedRectangle(cornerRadius: 4)
                        .fill(levelColor)
                        .frame(width: geometry.size.width * CGFloat(viewModel.audioLevel))
                }
            }
            .frame(height: 8)
        }
        .frame(width: 200)
    }

    private var levelColor: Color {
        switch viewModel.audioLevel {
        case 0.0..<0.6:
            return .green
        case 0.6..<0.8:
            return .yellow
        default:
            return .red
        }
    }

    private var audioIcon: String {
        if viewModel.audioLevel < 0.1 {
            return "speaker.fill"
        } else if viewModel.audioLevel < 0.5 {
            return "speaker.wave.1.fill"
        } else if viewModel.audioLevel < 0.8 {
            return "speaker.wave.2.fill"
        } else {
            return "speaker.wave.3.fill"
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        AudioLevelView(viewModel: DeviceViewModel())
        Text("Audio level from real capture device")
            .foregroundStyle(.secondary)
    }
    .padding()
    .background(Color.black)
}
