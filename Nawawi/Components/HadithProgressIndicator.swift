//
//  HadithProgressIndicator.swift
//  Nawawi
//
//  Visual progress indicator for hadith navigation
//

import SwiftUI

struct HadithProgressIndicator: View {
    let current: Int
    let total: Int
    @Binding var selectedIndex: Int

    private let maxVisibleDots = 10

    var body: some View {
        HStack(spacing: 6) {
            // Previous button
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    if selectedIndex > 0 {
                        selectedIndex -= 1
                    }
                }
            }) {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .disabled(selectedIndex == 0)
            .keyboardShortcut(.leftArrow, modifiers: [.command])

            // Progress dots or numbers
            if total <= maxVisibleDots {
                // Show all dots if total is small
                HStack(spacing: 4) {
                    ForEach(0..<total, id: \.self) { index in
                        DotIndicator(
                            isActive: index == selectedIndex,
                            number: index + 1,
                            action: {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedIndex = index
                                }
                            }
                        )
                    }
                }
            } else {
                // Show condensed view for many items
                HStack(spacing: 8) {
                    Text("\(current)")
                        .font(.nohemiNumber)
                        .foregroundStyle(.black)
                        .monospacedDigit()

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background track
                            Capsule()
                                .fill(Color.nawawi_cream.opacity(0.6))
                                .frame(height: 4)

                            // Progress fill
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.nawawi_darkGreen, Color.nawawi_lightGreen],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(
                                    width: geometry.size.width * CGFloat(current) / CGFloat(total),
                                    height: 4
                                )
                                .animation(.spring(response: 0.3), value: current)
                        }
                    }
                    .frame(width: 120, height: 4)

                    Text("\(total)")
                        .font(.nohemiCaptionLight)
                        .foregroundStyle(.gray)
                        .monospacedDigit()
                }
            }

            // Next button
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    if selectedIndex < total - 1 {
                        selectedIndex += 1
                    }
                }
            }) {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .disabled(selectedIndex >= total - 1)
            .keyboardShortcut(.rightArrow, modifiers: [.command])
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.nawawi_softCream)
        )
        .overlay(
            Capsule()
                .stroke(
                    Color.nawawi_darkGreen.opacity(0.15),
                    lineWidth: 0.5
                )
        )
        .nawawi_subtleShadow()
    }
}

struct DotIndicator: View {
    let isActive: Bool
    let number: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(isActive ? Color.nawawi_darkGreen : Color.nawawi_secondary.opacity(0.4))
                .frame(width: isActive ? 10 : 6, height: isActive ? 10 : 6)
                .overlay(
                    Text("\(number)")
                        .font(.system(size: 4))
                        .foregroundColor(.white)
                        .opacity(isActive ? 1 : 0)
                )
                .animation(.spring(response: 0.3), value: isActive)
        }
        .buttonStyle(.plain)
        .help("Hadith \(number)")
    }
}
