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

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspect
        previewLayer.frame = view.bounds
        previewLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        view.layer = previewLayer

        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        // Layer resizes automatically via autoresizingMask, nothing to update.
    }
}
