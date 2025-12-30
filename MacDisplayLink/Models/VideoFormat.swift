//
//  VideoFormat.swift
//  MacDisplayLink
//
//  Created by Claude on 12/30/25.
//

import Foundation
import AVFoundation

/// 캡처 디바이스의 비디오 포맷 정보
struct VideoFormat: Identifiable, Hashable {
    let id: String
    let width: Int
    let height: Int
    let frameRate: Double
    let format: AVCaptureDevice.Format

    /// 표시용 문자열 (예: "1920×1080 @ 60fps")
    var displayName: String {
        return "\(width)×\(height) @ \(Int(frameRate))fps"
    }

    /// 해상도만 표시 (예: "1920×1080")
    var resolutionString: String {
        return "\(width)×\(height)"
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: VideoFormat, rhs: VideoFormat) -> Bool {
        return lhs.id == rhs.id
    }

    // MARK: - 초기화

    init(format: AVCaptureDevice.Format) {
        self.format = format

        // 해상도 파싱
        let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
        self.width = Int(dimensions.width)
        self.height = Int(dimensions.height)

        // 프레임레이트 파싱 (최대 프레임레이트 사용)
        let frameRateRange = format.videoSupportedFrameRateRanges.first
        self.frameRate = frameRateRange?.maxFrameRate ?? 30.0

        // 고유 ID 생성
        self.id = "\(width)x\(height)@\(Int(frameRate))fps"
    }

    // MARK: - 헬퍼 메서드

    /// 해상도 비교 (큰 것부터 정렬용)
    var totalPixels: Int {
        return width * height
    }
}

// MARK: - 배열 확장

extension Array where Element == VideoFormat {
    /// 중복 제거 및 정렬 (해상도 높은 순, 프레임레이트 높은 순)
    func uniqueAndSorted() -> [VideoFormat] {
        // 중복 제거 (같은 해상도 & 프레임레이트)
        var seen = Set<String>()
        var unique: [VideoFormat] = []

        for format in self {
            if !seen.contains(format.id) {
                seen.insert(format.id)
                unique.append(format)
            }
        }

        // 정렬: 해상도 높은 순 → 프레임레이트 높은 순
        return unique.sorted { lhs, rhs in
            if lhs.totalPixels != rhs.totalPixels {
                return lhs.totalPixels > rhs.totalPixels // 해상도 높은 순
            } else {
                return lhs.frameRate > rhs.frameRate // 프레임레이트 높은 순
            }
        }
    }
}
