//
//  PreviewView.swift
//  MacDisplayLink
//
//  Created by Claude on 12/21/25.
//

import SwiftUI

struct PreviewView: View {
    @ObservedObject var viewModel: DeviceViewModel

    var body: some View {
        ZStack {
            // 배경 (검은색)
            Color.black

            if viewModel.hasSignal, let frame = viewModel.currentFrame {
                // 신호 있을 때: 프레임 표시
                frame
                    .resizable()
                    .aspectRatio(16/9, contentMode: .fit)
                    .foregroundStyle(.white.opacity(0.3))
            } else {
                // 신호 없을 때: "No Signal" 표시
                VStack(spacing: 16) {
                    Image(systemName: "antenna.radiowaves.left.and.right.slash")
                        .font(.system(size: 64))
                        .foregroundStyle(.white.opacity(0.5))

                    Text("No Signal")
                        .font(.title)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }

            // 신호 정보 오버레이 (우측 상단)
            if viewModel.hasSignal {
                VStack {
                    HStack {
                        Spacer()
                        Text(viewModel.signalInfo)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(8)
                            .background(.black.opacity(0.5))
                            .cornerRadius(4)
                            .padding()
                    }
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    PreviewView(viewModel: DeviceViewModel())
        .frame(width: 1280, height: 720)
}
