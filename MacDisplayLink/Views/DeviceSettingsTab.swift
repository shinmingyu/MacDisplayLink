//
//  DeviceSettingsTab.swift
//  MacDisplayLink
//
//  Created by Claude on 12/22/25.
//

import SwiftUI
import AVFoundation

struct DeviceSettingsTab: View {
    @ObservedObject var deviceViewModel: DeviceViewModel

    var body: some View {
        Form {
            Section {
                if deviceViewModel.isDeviceConnected {
                    // 디바이스 목록 표시
                    VStack(alignment: .leading, spacing: 12) {
                        Text("연결된 캡쳐 디바이스")
                            .font(.headline)

                        ForEach(deviceViewModel.captureDevices, id: \.uniqueID) { device in
                            DeviceRow(
                                device: device,
                                isSelected: deviceViewModel.selectedDevice?.uniqueID == device.uniqueID
                            )
                            .onTapGesture {
                                deviceViewModel.selectDevice(device)
                            }
                        }
                    }
                } else {
                    // 디바이스 미연결 상태
                    VStack(spacing: 16) {
                        Image(systemName: "antenna.radiowaves.left.and.right.slash")
                            .font(.system(size: 48))
                            .foregroundStyle(.gray)

                        Text("캡쳐 카드가 연결되지 않았습니다")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        Text("USB 캡쳐 카드를 Mac에 연결해주세요")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(40)
                }
            }

            Section {
                // 새로고침 버튼
                Button(action: {
                    deviceViewModel.refreshDevices()
                }) {
                    Label("디바이스 새로고침", systemImage: "arrow.clockwise")
                }
            }
        }
        .formStyle(.grouped)
    }
}

/// 디바이스 행 UI
struct DeviceRow: View {
    let device: AVCaptureDevice
    let isSelected: Bool

    var body: some View {
        HStack {
            Image(systemName: "video.fill")
                .foregroundStyle(isSelected ? .blue : .gray)

            VStack(alignment: .leading, spacing: 4) {
                Text(device.localizedName)
                    .font(.body)
                    .fontWeight(isSelected ? .semibold : .regular)

                Text("ID: \(device.uniqueID)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.blue)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
        )
    }
}

#Preview {
    DeviceSettingsTab(deviceViewModel: DeviceViewModel())
        .frame(width: 600, height: 500)
}
