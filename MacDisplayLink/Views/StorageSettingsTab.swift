//
//  StorageSettingsTab.swift
//  MacDisplayLink
//
//  Created by Claude on 12/21/25.
//

import SwiftUI

struct StorageSettingsTab: View {
    var body: some View {
        Form {
            Section("저장 위치") {
                HStack {
                    Text("저장 경로")
                    Spacer()
                    Text("~/Movies/MacDisplayLink")
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Button(action: {
                    openInFinder()
                }) {
                    Label("Finder에서 열기", systemImage: "folder")
                }
            }

            Section("파일명 형식") {
                HStack {
                    Text("형식")
                    Spacer()
                    Text("Recording_yyyyMMdd_HHmmss.mp4")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }

                Text("예시: Recording_20251221_143052.mp4")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private func openInFinder() {
        let homeURL = FileManager.default.homeDirectoryForCurrentUser
        let moviesURL = homeURL.appendingPathComponent("Movies/MacDisplayLink")

        // 디렉터리가 없으면 생성
        try? FileManager.default.createDirectory(at: moviesURL, withIntermediateDirectories: true)

        // Finder에서 열기
        NSWorkspace.shared.open(moviesURL)
    }
}

#Preview {
    StorageSettingsTab()
        .frame(width: 500, height: 400)
}
