//
//  ContentView.swift
//  MinimalSwiftUIApp
//
//  Root UI for the application. Additional screens belong in `Views/`.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("MinimalSwiftUIApp")
                .font(.title2)
            Text("Project scaffold is ready.")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

