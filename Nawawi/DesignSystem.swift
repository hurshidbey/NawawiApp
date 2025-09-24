//
//  DesignSystem.swift
//  Nawawi
//
//  Ultra-modern design system with Nohemi 2 typography and refined color palette
//

import SwiftUI

// MARK: - Nohemi Typography System
extension Font {
    // MARK: - Nohemi Font Family
    static func nohemi(_ weight: NohemiWeight, size: CGFloat) -> Font {
        return .custom(weight.fontName, size: size)
    }

    // MARK: - Typography Scale
    static let nohemiDisplay = Font.nohemi(.black, size: 32)
    static let nohemiTitle = Font.nohemi(.extraBold, size: 24)
    static let nohemiHeadline = Font.nohemi(.bold, size: 18)
    static let nohemiBody = Font.nohemi(.regular, size: 16)
    static let nohemiBodyMedium = Font.nohemi(.medium, size: 16)
    static let nohemiCaption = Font.nohemi(.medium, size: 12)
    static let nohemiCaptionLight = Font.nohemi(.light, size: 12)
    static let nohemiSmall = Font.nohemi(.regular, size: 10)

    // MARK: - UI Specific Fonts
    static let nohemiButton = Font.nohemi(.semiBold, size: 14)
    static let nohemiNavigation = Font.nohemi(.medium, size: 15)
    static let nohemiNumber = Font.nohemi(.medium, size: 14)
}

enum NohemiWeight: String, CaseIterable {
    case thin = "Thin"
    case extraLight = "ExtraLight"
    case light = "Light"
    case regular = "Regular"
    case medium = "Medium"
    case semiBold = "SemiBold"
    case bold = "Bold"
    case extraBold = "ExtraBold"
    case black = "Black"

    var fontName: String {
        return "Nohemi-\(self.rawValue)"
    }
}

// MARK: - Refined Color System
extension Color {
    // MARK: - Primary Colors
    static let nawawi_darkGreen = Color("DarkGreen")
    static let nawawi_cream = Color("Cream")
    static let nawawi_pureBlack = Color("Pure Black")

    // MARK: - Secondary Colors (Generated from primary palette)
    static let nawawi_lightGreen = Color(red: 0.176, green: 0.357, blue: 0.239) // #2D5A3D
    static let nawawi_softCream = Color(red: 0.980, green: 0.969, blue: 0.949) // #FAF7F2
    static let nawawi_charcoal = Color(red: 0.125, green: 0.125, blue: 0.125) // #202020

    // MARK: - Semantic Colors
    static let nawawi_background = nawawi_cream
    static let nawawi_surface = nawawi_softCream
    static let nawawi_primary = nawawi_darkGreen
    static let nawawi_onBackground = Color.black // Force pure black for text readability
    static let nawawi_onSurface = Color.black // Force pure black for text readability
    static let nawawi_secondary = Color(red: 0.3, green: 0.3, blue: 0.3) // Darker secondary text
    static let nawawi_accent = nawawi_darkGreen
}

// MARK: - Modern Spacing System
extension CGFloat {
    // 8px grid system for perfect alignment
    static let spacing_xs: CGFloat = 4
    static let spacing_sm: CGFloat = 8
    static let spacing_md: CGFloat = 16
    static let spacing_lg: CGFloat = 24
    static let spacing_xl: CGFloat = 32
    static let spacing_xxl: CGFloat = 48

    // Component specific spacing
    static let card_padding: CGFloat = 20
    static let button_padding_horizontal: CGFloat = 16
    static let button_padding_vertical: CGFloat = 8
    static let section_spacing: CGFloat = 24
}

// MARK: - Sophisticated Shadow System
extension View {
    func nawawi_cardShadow(elevated: Bool = false) -> some View {
        self.shadow(
            color: Color.black.opacity(elevated ? 0.08 : 0.04),
            radius: elevated ? 12 : 6,
            x: 0,
            y: elevated ? 4 : 2
        )
    }

    func nawawi_subtleShadow() -> some View {
        self.shadow(
            color: Color.black.opacity(0.02),
            radius: 2,
            x: 0,
            y: 1
        )
    }
}

// MARK: - Refined Material System
extension View {
    func nawawi_glassMaterial() -> some View {
        self
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
    }

    func nawawi_creamGlass() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.nawawi_cream.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                Color.nawawi_darkGreen.opacity(0.1),
                                lineWidth: 0.5
                            )
                    )
            )
    }
}

// MARK: - Enhanced Button Styles
struct NawawiButtonStyle: ButtonStyle {
    let variant: ButtonVariant

    enum ButtonVariant {
        case primary
        case secondary
        case subtle
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.nohemiButton)
            .foregroundColor(textColor)
            .padding(.horizontal, .button_padding_horizontal)
            .padding(.vertical, .button_padding_vertical)
            .background(backgroundColor(isPressed: configuration.isPressed))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: variant == .subtle ? 0 : 0.5)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: configuration.isPressed)
    }

    private var textColor: Color {
        switch variant {
        case .primary:
            return .nawawi_cream
        case .secondary:
            return .nawawi_darkGreen
        case .subtle:
            return .nawawi_secondary
        }
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        let baseColor: Color
        switch variant {
        case .primary:
            baseColor = .nawawi_darkGreen
        case .secondary:
            baseColor = .nawawi_softCream
        case .subtle:
            baseColor = .clear
        }
        return baseColor.opacity(isPressed ? 0.8 : 1.0)
    }

    private var borderColor: Color {
        switch variant {
        case .primary:
            return .clear
        case .secondary:
            return .nawawi_darkGreen.opacity(0.3)
        case .subtle:
            return .clear
        }
    }
}

// MARK: - Enhanced Card Component
struct NawawiCard<Content: View>: View {
    let content: Content
    let elevated: Bool

    init(elevated: Bool = false, @ViewBuilder content: () -> Content) {
        self.elevated = elevated
        self.content = content()
    }

    var body: some View {
        content
            .padding(.card_padding)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.nawawi_surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.nawawi_darkGreen.opacity(0.1),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
            .nawawi_cardShadow(elevated: elevated)
    }
}