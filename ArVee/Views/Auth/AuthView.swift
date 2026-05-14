import SwiftUI

// MARK: - Google "G" Logo (4-color arcs)

private struct GoogleLogo: View {
    var size: CGFloat = 20

    var body: some View {
        Canvas { context, canvasSize in
            let s = min(canvasSize.width, canvasSize.height)
            let center = CGPoint(x: s / 2, y: s / 2)
            let outer = s / 2
            let inner = s * 0.30
            let gap: Angle = .degrees(4)

            // Blue (right) — 315° to 45°
            drawArc(in: &context, center: center, outer: outer, inner: inner,
                    start: .degrees(-45), end: .degrees(45) - gap,
                    color: Color(red: 0.259, green: 0.522, blue: 0.957))

            // Green (bottom) — 45° to 135°
            drawArc(in: &context, center: center, outer: outer, inner: inner,
                    start: .degrees(45), end: .degrees(135) - gap,
                    color: Color(red: 0.204, green: 0.659, blue: 0.325))

            // Yellow (left-bottom) — 135° to 225°
            drawArc(in: &context, center: center, outer: outer, inner: inner,
                    start: .degrees(135), end: .degrees(225) - gap,
                    color: Color(red: 0.984, green: 0.737, blue: 0.020))

            // Red (top) — 225° to 315°
            drawArc(in: &context, center: center, outer: outer, inner: inner,
                    start: .degrees(225), end: .degrees(315) - gap,
                    color: Color(red: 0.918, green: 0.263, blue: 0.208))

            // Horizontal bar (blue, right side)
            let barH = s * 0.18
            let barRect = CGRect(x: center.x - s * 0.02, y: center.y - barH / 2,
                                 width: outer + s * 0.02 - center.x + outer * 0.08,
                                 height: barH)
            context.fill(Path(barRect),
                         with: .color(Color(red: 0.259, green: 0.522, blue: 0.957)))
        }
        .frame(width: size, height: size)
        .allowsHitTesting(false)
    }

    private func drawArc(in context: inout GraphicsContext,
                         center: CGPoint, outer: CGFloat, inner: CGFloat,
                         start: Angle, end: Angle, color: Color) {
        var path = Path()
        path.addArc(center: center, radius: outer,
                    startAngle: start, endAngle: end, clockwise: false)
        path.addArc(center: center, radius: inner,
                    startAngle: end, endAngle: start, clockwise: true)
        path.closeSubpath()
        context.fill(path, with: .color(color))
    }
}

// MARK: - Auth View

struct AuthView: View {
    @ObservedObject var viewModel: AuthViewModel
    @State private var appeared = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // ── Hero ──
                    heroSection
                        .padding(.top, 48)
                        .padding(.bottom, 32)

                    // ── Form Card ──
                    formCard
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)

                    // ── Divider ──
                    orDivider
                        .padding(.horizontal, 40)
                        .padding(.bottom, 16)

                    // ── Google ──
                    googleButton
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)

                    // ── Footer ──
                    footer
                        .padding(.bottom, 24)
                }
            }
            .arveePageBackground()
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.refreshAuthState()
                withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                    appeared = true
                }
            }
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 16) {
            ZStack {
                // Glow ring
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.arveeTeal.opacity(0.18), Color.clear],
                            center: .center,
                            startRadius: 30,
                            endRadius: 80
                        )
                    )
                    .frame(width: 140, height: 140)

                Image("icon2")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.6), lineWidth: 1)
                    )
                    .shadow(color: Color.arveeTeal.opacity(0.25), radius: 20, x: 0, y: 10)
            }
            .scaleEffect(appeared ? 1.0 : 0.8)
            .opacity(appeared ? 1.0 : 0.0)

            VStack(spacing: 8) {
                Text("ArVee")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.arveeInk)

                Text("Your receipts called.\nThey want to be validated.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.arveeInkMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
            .offset(y: appeared ? 0 : 12)
            .opacity(appeared ? 1.0 : 0.0)
        }
    }

    // MARK: - Form Card

    private var formCard: some View {
        VStack(spacing: 20) {
            // Segmented picker
            Picker("Mode", selection: $viewModel.mode) {
                ForEach(AuthViewModel.AuthMode.allCases) { m in
                    Text(m.rawValue).tag(m)
                }
            }
            .pickerStyle(.segmented)
            .scaleEffect(0.9)

            // Input fields
            VStack(spacing: 14) {
                authField(icon: "envelope.fill", placeholder: "Email") {
                    TextField("Email", text: $viewModel.email)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)
                }

                authField(icon: "lock.fill", placeholder: "Password") {
                    SecureField("Password", text: $viewModel.password)
                }

                if viewModel.mode == .signup {
                    authField(icon: "lock.rotation", placeholder: "Confirm Password") {
                        SecureField("Confirm Password", text: $viewModel.confirmPassword)
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.25), value: viewModel.mode)

            // Error message
            if let error = viewModel.errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                    Text(error)
                        .font(.system(.caption, design: .rounded))
                }
                .foregroundColor(.arveeDanger)
                .frame(maxWidth: .infinity, alignment: .leading)
                .transition(.opacity)
            }

            // Primary CTA
            Button {
                Task { await viewModel.submit() }
            } label: {
                Group {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(viewModel.mode == .signup ? "Create Account" : "Sign In")
                            .font(.system(.body, design: .rounded).weight(.semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(ArveePrimaryButtonStyle())
            .scaleEffect(0.85)
            .disabled(viewModel.isLoading)
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.arveeInk.opacity(0.06), radius: 16, x: 0, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.arveeLine, lineWidth: 0.5)
        )
        .offset(y: appeared ? 0 : 20)
        .opacity(appeared ? 1.0 : 0.0)
    }

    // MARK: - Field Row

    private func authField<Content: View>(
        icon: String,
        placeholder: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.arveeTeal)
                .frame(width: 20)

            content()
                .font(.system(.body, design: .rounded))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.arveeCardElevated)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.arveeLine, lineWidth: 0.5)
        )
    }

    // MARK: - Or Divider

    private var orDivider: some View {
        HStack(spacing: 14) {
            dashedLine
            Text("or")
                .font(.system(.caption, design: .rounded).weight(.medium))
                .foregroundColor(.arveeInkMuted)
            dashedLine
        }
        .opacity(appeared ? 1.0 : 0.0)
    }

    private var dashedLine: some View {
        Rectangle()
            .fill(Color.arveeLine)
            .frame(height: 1)
    }

    // MARK: - Google Button

    private var googleButton: some View {
        Button {
            Task { await viewModel.submitGoogle() }
        } label: {
            HStack(spacing: 12) {
                GoogleLogo(size: 20)

                Text("Continue with Google")
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundColor(.arveeInk)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.arveeCardElevated)
                    .shadow(color: Color.arveeInk.opacity(0.04), radius: 8, x: 0, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.arveeLine, lineWidth: 0.7)
            )
            .contentShape(Rectangle())
        }
        .disabled(viewModel.isLoading)
        .offset(y: appeared ? 0 : 12)
        .opacity(appeared ? 1.0 : 0.0)
    }

    // MARK: - Footer

    private var footer: some View {
        Text("Secured with end-to-end encryption")
            .font(.system(.caption2, design: .rounded))
            .foregroundColor(.arveeInkMuted.opacity(0.6))
            .opacity(appeared ? 1.0 : 0.0)
    }
}
