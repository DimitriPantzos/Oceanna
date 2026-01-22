import SwiftUI

// MARK: - Oceanna Design System
// Minimal, premium aesthetic inspired by Erewhon / Le Labo / Apple

struct OceannaTheme {
    // MARK: - Colors (Pure Monochrome)
    struct Colors {
        static let primary = Color.black
        static let background = Color.white
        static let secondaryBackground = Color(uiColor: .systemGray6)
        static let tertiaryBackground = Color(uiColor: .systemGray5)
        static let primaryText = Color.black
        static let secondaryText = Color(uiColor: .systemGray)
        static let tertiaryText = Color(uiColor: .systemGray2)
        static let border = Color(uiColor: .systemGray4)
        static let divider = Color(uiColor: .systemGray5)
    }

    // MARK: - Typography
    struct Typography {
        // UI Text - SF Pro
        static let largeTitle = Font.system(size: 34, weight: .bold)
        static let title = Font.system(size: 28, weight: .bold)
        static let title2 = Font.system(size: 22, weight: .bold)
        static let title3 = Font.system(size: 20, weight: .semibold)
        static let headline = Font.system(size: 17, weight: .semibold)
        static let body = Font.system(size: 17, weight: .regular)
        static let callout = Font.system(size: 16, weight: .regular)
        static let subheadline = Font.system(size: 15, weight: .regular)
        static let footnote = Font.system(size: 13, weight: .regular)
        static let caption = Font.system(size: 12, weight: .regular)

        // Monospace - SF Mono (for tags, skills, metadata)
        static let monoLarge = Font.system(size: 15, weight: .medium, design: .monospaced)
        static let mono = Font.system(size: 13, weight: .medium, design: .monospaced)
        static let monoSmall = Font.system(size: 11, weight: .medium, design: .monospaced)
    }

    // MARK: - Spacing
    struct Spacing {
        static let xxxs: CGFloat = 2
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        static let xxxl: CGFloat = 64
    }

    // MARK: - Corner Radius
    struct Radius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let full: CGFloat = 9999
    }

    // MARK: - Card Style
    struct Card {
        static let borderWidth: CGFloat = 1
        static let padding: CGFloat = 16
        static let imagePadding: CGFloat = 12  // White frame around images
    }
}

// MARK: - View Modifiers

struct OceannaButtonStyle: ButtonStyle {
    let isPrimary: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(OceannaTheme.Typography.headline)
            .foregroundColor(isPrimary ? .white : OceannaTheme.Colors.primary)
            .padding(.horizontal, OceannaTheme.Spacing.lg)
            .padding(.vertical, OceannaTheme.Spacing.sm)
            .background(isPrimary ? OceannaTheme.Colors.primary : .clear)
            .overlay(
                RoundedRectangle(cornerRadius: OceannaTheme.Radius.sm)
                    .stroke(OceannaTheme.Colors.primary, lineWidth: isPrimary ? 0 : 1)
            )
            .cornerRadius(OceannaTheme.Radius.sm)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

struct MonoTagStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(OceannaTheme.Typography.mono)
            .foregroundColor(OceannaTheme.Colors.primaryText)
            .padding(.horizontal, OceannaTheme.Spacing.xs)
            .padding(.vertical, OceannaTheme.Spacing.xxs)
            .background(OceannaTheme.Colors.secondaryBackground)
            .cornerRadius(OceannaTheme.Radius.xs)
    }
}

extension View {
    func oceannaButton(isPrimary: Bool = true) -> some View {
        buttonStyle(OceannaButtonStyle(isPrimary: isPrimary))
    }

    func monoTag() -> some View {
        modifier(MonoTagStyle())
    }
}

struct OceannaTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(OceannaTheme.Typography.body)
            .padding(OceannaTheme.Spacing.md)
            .background(OceannaTheme.Colors.secondaryBackground)
            .cornerRadius(OceannaTheme.Radius.sm)
    }
}
