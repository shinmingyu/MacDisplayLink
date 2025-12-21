//
//  ContentView.swift
//  MacDisplayLink
//
//  Created by Claude on 12/21/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "video.circle")
                .imageScale(.large)
                .font(.system(size: 64))
                .foregroundStyle(.tint)
            Text("MacDisplayLink")
                .font(.title)
                .padding()
            Text("프로젝트 설정 완료")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(minWidth: 1280, minHeight: 720)
    }
}

#Preview {
    ContentView()
}
