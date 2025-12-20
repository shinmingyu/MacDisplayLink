//
//  VideoPreviewView.swift
//  MacDisplayLink
//
//  Created by Codex.
//

import AVFoundation
import SwiftUI

struct VideoPreviewView: NSViewRepresentable {
    let session: AVCaptureSession
    let rotationDegrees: Double
    let flipHorizontal: Bool
    let flipVertical: Bool

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspect
        previewLayer.frame = view.bounds
        previewLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        previewLayer.setAffineTransform(makeTransform())
        view.layer = previewLayer

        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let layer = nsView.layer as? AVCaptureVideoPreviewLayer else { return }
        layer.setAffineTransform(makeTransform())
    }

    private func makeTransform() -> CGAffineTransform {
        var transform = CGAffineTransform.identity
        if flipHorizontal {
            transform = transform.scaledBy(x: -1, y: 1)
        }
        if flipVertical {
            transform = transform.scaledBy(x: 1, y: -1)
        }
        let radians = rotationDegrees * .pi / 180
        transform = transform.rotated(by: radians)
        return transform
    }
}
