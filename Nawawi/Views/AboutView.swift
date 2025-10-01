//
//  AboutView.swift
//  Nawawi
//
//  Credits, attributions, and legal information
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(Color.nawawi_darkGreen)

                    VStack(spacing: 8) {
                        Text("40 Hadith Nawawi")
                            .font(.nohemiTitle)
                            .foregroundColor(.black)

                        Text("أربعون النووية")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color.nawawi_darkGreen)

                        Text("Version 1.0.0")
                            .font(.nohemiCaption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.top, 20)

                Divider()

                // Islamic Blessing
                VStack(spacing: 12) {
                    Text("بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.black)
                        .environment(\.layoutDirection, .rightToLeft)

                    Text("In the name of Allah, the Most Gracious, the Most Merciful")
                        .font(.nohemiCaption)
                        .foregroundColor(.gray)
                        .italic()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.nawawi_softCream)
                )

                // Scholarly Source
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Scholarly Source", systemImage: "graduationcap.fill")
                            .font(.nohemiHeadline)
                            .foregroundColor(.black)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Original Compilation")
                                .font(.nohemiButton)
                                .foregroundColor(.black)
                            Text("Imam Yahya ibn Sharaf al-Nawawi (1233-1277 CE)")
                                .font(.nohemiCaption)
                                .foregroundColor(.gray)

                            Text("Hadith Sources")
                                .font(.nohemiButton)
                                .foregroundColor(.black)
                                .padding(.top, 8)
                            Text("Authenticated from online Islamic scholarly databases including Sunnah.com and 40HadithNawawi.com")
                                .font(.nohemiCaption)
                                .foregroundColor(.gray)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Text("⚠️ Disclaimer: This app is for educational purposes only. Please consult qualified Islamic scholars for religious guidance and interpretation.")
                            .font(.nohemiCaption)
                            .foregroundColor(.orange)
                            .padding(.top, 8)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Typography Credits
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Typography", systemImage: "textformat")
                            .font(.nohemiHeadline)
                            .foregroundColor(.black)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Nohemi Font Family")
                                .font(.nohemiButton)
                                .foregroundColor(.black)
                            Text("Designed by Pangram Pangram Foundry")
                                .font(.nohemiCaption)
                                .foregroundColor(.gray)
                            Text("Commercial License purchased from Gumroad")
                                .font(.nohemiCaption)
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Privacy
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Privacy & Data", systemImage: "lock.shield.fill")
                            .font(.nohemiHeadline)
                            .foregroundColor(.black)

                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("No data collection")
                                    .font(.nohemiBody)
                                    .foregroundColor(.black)
                            }

                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("No analytics or tracking")
                                    .font(.nohemiBody)
                                    .foregroundColor(.black)
                            }

                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("All data stays on your device")
                                    .font(.nohemiBody)
                                    .foregroundColor(.black)
                            }

                            Button(action: {
                                if let url = URL(string: "https://github.com/yourusername/nawawi-privacy-policy") {
                                    NSWorkspace.shared.open(url)
                                }
                            }) {
                                Text("View Full Privacy Policy")
                                    .font(.nohemiCaption)
                                    .foregroundColor(Color.nawawi_darkGreen)
                            }
                            .buttonStyle(.link)
                            .padding(.top, 4)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Developer
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Developer", systemImage: "person.fill")
                            .font(.nohemiHeadline)
                            .foregroundColor(.black)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Khurshid Marazikov")
                                .font(.nohemiBody)
                                .foregroundColor(.black)
                            Text("birfoizProject")
                                .font(.nohemiCaption)
                                .foregroundColor(.gray)
                            Text("Copyright © 2025 All rights reserved.")
                                .font(.nohemiCaption)
                                .foregroundColor(.gray)
                                .padding(.top, 4)
                        }

                        HStack(spacing: 16) {
                            Button(action: {
                                if let url = URL(string: "mailto:support@40hadithnawawi.com") {
                                    NSWorkspace.shared.open(url)
                                }
                            }) {
                                Label("Support", systemImage: "envelope.fill")
                                    .font(.nohemiCaption)
                            }
                            .buttonStyle(.link)

                            Button(action: {
                                if let url = URL(string: "https://github.com/yourusername/40-hadith-nawawi") {
                                    NSWorkspace.shared.open(url)
                                }
                            }) {
                                Label("Source", systemImage: "chevron.left.forwardslash.chevron.right")
                                    .font(.nohemiCaption)
                            }
                            .buttonStyle(.link)
                        }
                        .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Technologies
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Built With", systemImage: "hammer.fill")
                            .font(.nohemiHeadline)
                            .foregroundColor(.black)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("• SwiftUI & AppKit")
                            Text("• Sparkle (MIT License)")
                            Text("• Sentry (BSD-3-Clause)")
                        }
                        .font(.nohemiCaption)
                        .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Closing
                VStack(spacing: 8) {
                    Text("اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ")
                        .font(.system(size: 16))
                        .foregroundColor(.black)
                        .environment(\.layoutDirection, .rightToLeft)

                    Text("May Allah accept this humble effort")
                        .font(.nohemiCaption)
                        .foregroundColor(.gray)
                        .italic()
                }
                .padding()
                .padding(.bottom, 20)
            }
            .padding(32)
        }
        .frame(width: 600, height: 700)
        .background(Color.nawawi_background)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("Close") {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    AboutView()
}
