import SwiftUI

struct StatusBanner: View {
    let message: String
    let type: BannerType

    enum BannerType {
        case error, info, success

        var color: Color {
            switch self {
            case .error: return .arveeDanger
            case .info: return .arveeTeal
            case .success: return .arveeMint
            }
        }

        var textColor: Color {
            switch self {
            case .error, .info: return .white
            case .success: return .arveeTealDark
            }
        }

        var icon: String {
            switch self {
            case .error: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            case .success: return "checkmark.circle.fill"
            }
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: type.icon)
            Text(message)
                .font(.system(.subheadline, design: .rounded))
                .multilineTextAlignment(.leading)
            Spacer()
        }
        .foregroundColor(type.textColor)
        .padding(12)
        .background(type.color.opacity(type == .success ? 1.0 : 0.9))
        .cornerRadius(10)
        .shadow(color: type.color.opacity(0.15), radius: 6, x: 0, y: 2)
        .padding(.horizontal)
    }
}

struct LoadingOverlay: View {
    let message: String

    var body: some View {
        ZStack {
            Color.arveeInk.opacity(0.2)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.3)
                    .tint(.arveeTeal)
                Text(message)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.arveeInkMuted)
            }
            .padding(32)
            .background(Color.arveeCard)
            .cornerRadius(16)
            .shadow(color: Color.arveeInk.opacity(0.1), radius: 20, x: 0, y: 8)
        }
    }
}
