//
//  StorageSettingsTab.swift
//  MacDisplayLink
//
//  Created by Claude on 12/21/25.
//

import SwiftUI

struct StorageSettingsTab: View {
    @State private var displayPath: String = ""

    var body: some View {
        Form {
            Section("저장 위치") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("저장 경로")
                        .font(.subheadline)
                    Text(displayPath)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                        .lineLimit(2)
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
        .onAppear {
            updateDisplayPath()
        }
    }

    private func getRecordingsURL() -> URL {
        // App Sandbox 환경에서 접근 가능한 Documents 디렉터리 사용
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsURL.appendingPathComponent("Recordings")
    }

    private func updateDisplayPath() {
        let url = getRecordingsURL()
        displayPath = url.path.replacingOccurrences(
            of: FileManager.default.homeDirectoryForCurrentUser.path,
            with: "~"
        )
    }

    private func openInFinder() {
        let recordingsURL = getRecordingsURL()

        // 디렉터리가 없으면 생성
        try? FileManager.default.createDirectory(at: recordingsURL, withIntermediateDirectories: true)

        // Finder에서 열기
        NSWorkspace.shared.open(recordingsURL)
    }
}

#Preview {
    StorageSettingsTab()
        .frame(width: 500, height: 400)
}
