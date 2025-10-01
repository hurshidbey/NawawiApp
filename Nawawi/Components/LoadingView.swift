//
//  LoadingView.swift
//  Nawawi
//
//  Reusable loading state view with animation
//  Extracted from MenuBarView for component reusability
//

import SwiftUI

struct LoadingView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.circle")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.accentColor, .accentColor.opacity(0.5)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: isAnimating)

            Text("Loading Hadiths...")
                .font(.headline)
                .foregroundColor(.black)

            ProgressView()
                .progressViewStyle(.linear)
                .frame(width: 200)
        }
        .padding(40)
        .onAppear {
            isAnimating = true
        }
    }
}
