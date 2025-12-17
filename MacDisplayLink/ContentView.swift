//
//  ContentView.swift
//  MacDisplayLink
//
//  Created by 신민규 on 12/1/25.
//
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var deviceManager = CaptureDeviceManager()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Video Capture Devices")
                .font(.headline)

            if deviceManager.videoDevices.isEmpty {
                Text("No video capture devices found.")
                    .foregroundStyle(.secondary)
            } else {
                List(deviceManager.videoDevices, id: \.uniqueID) { device in
                    VStack(alignment: .leading) {
                        Text(device.localizedName)
                        Text(device.uniqueID)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
