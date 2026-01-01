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
    let pixelFormat: String  // "420v", "420f", "2vuy" 등
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

        // 픽셀 포맷 파싱
        let mediaSubType = CMFormatDescriptionGetMediaSubType(format.formatDescription)
        self.pixelFormat = VideoFormat.fourCCToString(mediaSubType)

        // 고유 ID 생성 (해상도, 프레임레이트, 픽셀 포맷 포함)
        self.id = "\(width)x\(height)@\(Int(frameRate))fps_\(pixelFormat)"
    }

    /// FourCC 코드를 문자열로 변환
    static func fourCCToString(_ fourCC: FourCharCode) -> String {
        let chars: [UInt8] = [
            UInt8((fourCC >> 24) & 0xFF),
            UInt8((fourCC >> 16) & 0xFF),
            UInt8((fourCC >> 8) & 0xFF),
            UInt8(fourCC & 0xFF)
        ]
        return String(bytes: chars, encoding: .ascii) ?? "unknown"
    }

    // MARK: - 헬퍼 메서드

    /// 해상도 비교 (큰 것부터 정렬용)
    var totalPixels: Int {
        return width * height
    }
}

// MARK: - 배열 확장

extension Array where Element == VideoFormat {
    /// 중복 제거 및 정렬 (해상도 높은 순, 프레임레이트 높은 순, 420v 우선)
    func uniqueAndSorted() -> [VideoFormat] {
        // 해상도@프레임레이트 조합별로 그룹화
        var groups: [String: [VideoFormat]] = [:]

        for format in self {
            let key = "\(format.width)x\(format.height)@\(Int(format.frameRate))fps"
            groups[key, default: []].append(format)
        }

        // 각 그룹에서 최적의 픽셀 포맷 선택 (420v 우선)
        var unique: [VideoFormat] = []

        for (_, formats) in groups {
            // 픽셀 포맷 우선순위: 420v > 420f > 기타
            let prioritized = formats.sorted { lhs, rhs in
                return pixelFormatPriority(lhs.pixelFormat) > pixelFormatPriority(rhs.pixelFormat)
            }

            if let best = prioritized.first {
                unique.append(best)
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

    /// 픽셀 포맷 우선순위 (높을수록 선호됨)
    private func pixelFormatPriority(_ pixelFormat: String) -> Int {
        switch pixelFormat {
        case "420v": return 100  // Video Range YUV 4:2:0 (가장 선호)
        case "420f": return 90   // Full Range YUV 4:2:0
        case "2vuy": return 80   // UYVY 4:2:2
        default: return 0        // 기타 포맷
        }
    }
}
