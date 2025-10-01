//
//  ShortcutRow.swift
//  Nawawi
//
//  Reusable keyboard shortcut display row
//  Extracted from MenuBarView for component reusability
//

import SwiftUI

struct ShortcutRow: View {
    let keys: String
    let action: String

    var body: some View {
        HStack {
            Text(keys)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.black)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.quaternary)
                )

            Text(action)
                .font(.caption)
                .foregroundStyle(Color(red: 0.4, green: 0.4, blue: 0.4))

            Spacer()
        }
    }
}
