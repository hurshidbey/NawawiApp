//
//  SearchBar.swift
//  Nawawi
//
//  Custom search bar with highlighting support
//

import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    let placeholder: String
    let onClear: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.gray)
                .symbolEffect(.pulse, isActive: !text.isEmpty)

            TextField(placeholder, text: $text)
                .font(.nohemiBody)
                .foregroundStyle(.black)
                .textFieldStyle(.plain)
                .focused(isFocused)
                .onSubmit {
                    // Keep focus on search
                    isFocused.wrappedValue = true
                }

            if !text.isEmpty {
                Button(action: {
                    text = ""
                    onClear()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.gray)
                        .symbolEffect(.bounce, value: text)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.escape, modifiers: [])
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.nawawi_softCream)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            Color.nawawi_darkGreen.opacity(0.2),
                            lineWidth: 0.5
                        )
                )
        )
        .nawawi_subtleShadow()
        .animation(.spring(response: 0.3), value: text)
    }
}

// Text highlighting helper
struct HighlightedText: View {
    let text: String
    let highlight: String
    let font: Font
    let color: Color

    init(_ text: String, highlight: String, font: Font = .nohemiBody, color: Color = .black) {
        self.text = text
        self.highlight = highlight
        self.font = font
        self.color = color
    }

    var body: some View {
        if highlight.isEmpty {
            Text(text)
                .font(font)
                .foregroundColor(color)
        } else {
            let parts = text.components(separatedBy: highlight)
            HStack(spacing: 0) {
                ForEach(Array(parts.enumerated()), id: \.offset) { index, part in
                    Text(part)
                        .font(font)
                        .foregroundColor(color)
                    if index < parts.count - 1 {
                        Text(highlight)
                            .font(font)
                            .foregroundColor(Color.nawawi_darkGreen)
                            .fontWeight(.semibold)
                            .background(Color.nawawi_darkGreen.opacity(0.15))
                    }
                }
            }
        }
    }
}
