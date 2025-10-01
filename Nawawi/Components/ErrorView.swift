//
//  ErrorView.swift
//  Nawawi
//
//  Reusable error state view with retry action
//  Extracted from MenuBarView for component reusability
//

import SwiftUI

struct ErrorView: View {
    let error: Error
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundStyle(.orange)
                .symbolEffect(.bounce)

            Text("Unable to Load Hadiths")
                .foregroundColor(.black)
                .font(.headline)

            Text(error.localizedDescription)
                .font(.caption)
                .foregroundColor(.black)
                .multilineTextAlignment(.center)

            Button("Try Again", action: retry)
                .buttonStyle(.borderedProminent)
        }
        .padding(40)
    }
}
