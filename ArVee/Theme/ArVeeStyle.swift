import SwiftUI

// MARK: - Card Style Modifier

struct ArveeCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .background(Color.arveeCard)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.arveeLine, lineWidth: 0.5)
            )
            .shadow(color: Color.arveeInk.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}

extension View {
    func arveeCard(cornerRadius: CGFloat = 16) -> some View {
        modifier(ArveeCardModifier(cornerRadius: cornerRadius))
    }
}

// MARK: - Page Background

struct ArveePageBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.arveePaper.ignoresSafeArea())
    }
}

extension View {
    func arveePageBackground() -> some View {
        modifier(ArveePageBackground())
    }
}

// MARK: - Primary Button Style (Teal gradient)

struct ArveePrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, design: .rounded).weight(.semibold))
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .background(
                Group {
                    if isEnabled {
                        Color.arveeTealGradient
                    } else {
                        LinearGradient(
                            colors: [Color.arveeTeal.opacity(0.4), Color.arveeTealDark.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
            )
            .cornerRadius(11)
            .shadow(color: Color.arveeTeal.opacity(configuration.isPressed ? 0 : 0.2), radius: 8, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Secondary Button Style (Dark ink)

struct ArveeSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, design: .rounded).weight(.semibold))
            .foregroundColor(.white)
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(isEnabled ? Color.arveeInk : Color.arveeInk.opacity(0.4))
            .cornerRadius(11)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Tertiary Button Style (Sand)

struct ArveeTertiaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.subheadline, design: .rounded).weight(.medium))
            .foregroundColor(.arveeInk)
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(Color.arveeSand)
            .cornerRadius(11)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Danger Button Style

struct ArveeDangerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.subheadline, design: .rounded).weight(.medium))
            .foregroundColor(.white)
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(Color.arveeDanger)
            .cornerRadius(11)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Text Field Style

struct ArveeTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(.body, design: .monospaced))
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.arveeSand.opacity(0.5))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.arveeLine, lineWidth: 0.5)
            )
    }
}

// MARK: - Chat Bubble Shape (flat corner on sender side)

struct BubbleShape: Shape {
    let isUser: Bool

    func path(in rect: CGRect) -> Path {
        let r: CGFloat = 16
        let flat: CGFloat = 4

        let tl = isUser ? r : flat
        let tr = isUser ? r : r
        let br = isUser ? flat : r
        let bl = isUser ? r : r

        return Path { p in
            p.move(to: CGPoint(x: rect.minX + tl, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX - tr, y: rect.minY))
            p.addArc(tangent1End: CGPoint(x: rect.maxX, y: rect.minY),
                      tangent2End: CGPoint(x: rect.maxX, y: rect.minY + tr),
                      radius: tr)
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - br))
            p.addArc(tangent1End: CGPoint(x: rect.maxX, y: rect.maxY),
                      tangent2End: CGPoint(x: rect.maxX - br, y: rect.maxY),
                      radius: br)
            p.addLine(to: CGPoint(x: rect.minX + bl, y: rect.maxY))
            p.addArc(tangent1End: CGPoint(x: rect.minX, y: rect.maxY),
                      tangent2End: CGPoint(x: rect.minX, y: rect.maxY - bl),
                      radius: bl)
            p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + tl))
            p.addArc(tangent1End: CGPoint(x: rect.minX, y: rect.minY),
                      tangent2End: CGPoint(x: rect.minX + tl, y: rect.minY),
                      radius: tl)
        }
    }
}

// MARK: - Dashed Border Modifier (for upload dropzones)

struct ArveeDashedBorder: ViewModifier {
    var cornerRadius: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        Color.arveeTeal.opacity(0.5),
                        style: StrokeStyle(lineWidth: 1.5, dash: [8, 5])
                    )
            )
    }
}

extension View {
    func arveeDashedBorder(cornerRadius: CGFloat = 12) -> some View {
        modifier(ArveeDashedBorder(cornerRadius: cornerRadius))
    }
}
