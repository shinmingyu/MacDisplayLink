//
//  MockAudioViewModel.swift
//  MacDisplayLink
//
//  Created by Claude on 12/21/25.
//

import SwiftUI
import Combine

class MockAudioViewModel: ObservableObject {
    @Published var audioLevel: Float = 0.3

    private var timer: Timer?

    init() {
        // 0.1초마다 오디오 레벨 변동 시뮬레이션
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateAudioLevel()
        }
    }

    deinit {
        timer?.invalidate()
    }

    private func updateAudioLevel() {
        // 0.0 ~ 1.0 사이의 랜덤 값 생성 (부드러운 변화)
        let randomChange = Float.random(in: -0.1...0.1)
        audioLevel = max(0.0, min(1.0, audioLevel + randomChange))
    }
}
