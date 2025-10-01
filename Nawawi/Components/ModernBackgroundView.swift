//
//  ModernBackgroundView.swift
//  Nawawi
//
//  Animated gradient background with subtle texture
//  Extracted from MenuBarView for component reusability
//

import SwiftUI

struct ModernBackgroundView: View {
    var body: some View {
        ZStack {
            // Base cream layer
            Rectangle()
                .fill(Color.nawawi_background)

            // Subtle texture overlay
            LinearGradient(
                stops: [
                    .init(color: Color.clear, location: 0),
                    .init(color: Color.nawawi_darkGreen.opacity(0.01), location: 0.5),
                    .init(color: Color.clear, location: 1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Animated subtle accent
            TimelineView(.animation(minimumInterval: 2.0)) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate

                RadialGradient(
                    colors: [
                        Color.nawawi_darkGreen.opacity(0.008),
                        Color.clear
                    ],
                    center: UnitPoint(
                        x: 0.5 + 0.2 * sin(time * 0.3),
                        y: 0.5 + 0.2 * cos(time * 0.2)
                    ),
                    startRadius: 80,
                    endRadius: 300
                )
                .blur(radius: 40)
            }
        }
        .ignoresSafeArea()
    }
}
