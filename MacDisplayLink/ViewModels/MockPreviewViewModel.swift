//
//  MockPreviewViewModel.swift
//  MacDisplayLink
//
//  Created by Claude on 12/21/25.
//

import SwiftUI
import Combine

class MockPreviewViewModel: ObservableObject {
    @Published var currentFrame: Image?
    @Published var hasSignal: Bool = true
    @Published var signalInfo: String = "1920×1080 @ 60fps"

    private var timer: Timer?

    init() {
        // 테스트 이미지 생성 (컬러 그라디언트)
        currentFrame = createMockFrame()

        // 2초마다 프레임 업데이트 시뮬레이션
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updateFrame()
        }
    }

    deinit {
        timer?.invalidate()
    }

    private func createMockFrame() -> Image {
        // SF Symbol 아이콘으로 Mock 이미지 생성
        return Image(systemName: "video.fill")
    }

    private func updateFrame() {
        // 프레임 업데이트 시뮬레이션 (실제로는 같은 이미지)
        currentFrame = createMockFrame()
    }
}
