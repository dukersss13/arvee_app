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
            .background(
                LinearGradient(
                    colors: [Color.arveePaper, Color.arveeSand.opacity(0.35)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
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

// MARK: - Gradient Accent Card (top-edge tinted card)

struct ArveeGradientCardModifier: ViewModifier {
    var accentColor: Color = .arveeTeal
    var cornerRadius: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .background(
                ZStack(alignment: .top) {
                    Color.arveeCard
                    LinearGradient(
                        colors: [accentColor.opacity(0.12), accentColor.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .center
                    )
                }
            )
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.arveeLine, lineWidth: 0.5)
            )
            .shadow(color: Color.arveeInk.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}

extension View {
    func arveeGradientCard(accent: Color = .arveeTeal, cornerRadius: CGFloat = 16) -> some View {
        modifier(ArveeGradientCardModifier(accentColor: accent, cornerRadius: cornerRadius))
    }
}

// MARK: - Step Indicator

enum StepState {
    case pending, active, complete
}

struct StepIndicator: View {
    let steps: [(label: String, state: StepState)]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.offset) { idx, step in
                HStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(fillColor(for: step.state))
                            .frame(width: 28, height: 28)
                        if step.state == .complete {
                            Image(systemName: "checkmark")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.white)
                        } else {
                            Text("\(idx + 1)")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(step.state == .active ? .white : .arveeInkMuted)
                        }
                    }
                    Text(step.label)
                        .font(.system(size: 12, weight: step.state == .active ? .semibold : .medium, design: .rounded))
                        .foregroundColor(step.state == .pending ? .arveeInkMuted : .arveeInk)
                        .fixedSize(horizontal: true, vertical: false)
                }
                .fixedSize()

                if idx < steps.count - 1 {
                    lineSegment(completed: step.state == .complete)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func fillColor(for state: StepState) -> Color {
        switch state {
        case .complete: return .arveeStepComplete
        case .active: return .arveeStepActive
        case .pending: return .arveeStepPending
        }
    }

    private func lineSegment(completed: Bool) -> some View {
        Rectangle()
            .fill(completed ? Color.arveeStepComplete : Color.arveeStepPending)
            .frame(height: 2)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 4)
    }
}

// MARK: - File Row (selected file with remove button)

struct ArveeFileRow: View {
    let filename: String
    let subtitle: String?
    let onRemove: () -> Void

    init(filename: String, subtitle: String? = nil, onRemove: @escaping () -> Void) {
        self.filename = filename
        self.subtitle = subtitle
        self.onRemove = onRemove
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: fileIcon)
                .font(.body)
                .foregroundColor(.arveeTeal)
                .frame(width: 32, height: 32)
                .background(Color.arveeTealSoft)
                .cornerRadius(8)
            VStack(alignment: .leading, spacing: 1) {
                Text(filename)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.arveeInk)
                    .lineLimit(1)
                    .truncationMode(.middle)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.arveeInkMuted)
                }
            }
            Spacer()
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.body)
                    .foregroundColor(.arveeInkMuted)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.arveeSand.opacity(0.25))
        .cornerRadius(10)
    }

    private var fileIcon: String {
        let ext = (filename as NSString).pathExtension.lowercased()
        switch ext {
        case "pdf": return "doc.richtext"
        case "csv": return "tablecells"
        case "jpg", "jpeg", "png", "heic": return "photo"
        default: return "doc"
        }
    }
}

// MARK: - Pill Button Style (for suggestion chips)

struct ArveePillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.subheadline, design: .rounded).weight(.medium))
            .foregroundColor(.arveeTeal)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.arveeTealSoft)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.arveeTeal.opacity(0.15), lineWidth: 0.5)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Metric Card (dashboard KPI)

struct ArveeMetricCard: View {
    let title: String
    let value: String
    let icon: String
    var accentColor: Color = .arveeTeal

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(.arveeInkMuted)
                    .tracking(0.5)
                Spacer()
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(accentColor.opacity(0.6))
            }
            Text(value)
                .font(.system(size: 28.8, weight: .bold, design: .rounded))
                .foregroundColor(.arveeInk)
                .contentTransition(.numericText())
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .arveeGradientCard(accent: accentColor, cornerRadius: 14)
    }
}
