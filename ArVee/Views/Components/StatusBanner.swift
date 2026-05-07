import SwiftUI

struct StatusBanner: View {
    let message: String
    let type: BannerType

    enum BannerType {
        case error, info, success

        var color: Color {
            switch self {
            case .error: return .red
            case .info: return .blue
            case .success: return .green
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
                .font(.subheadline)
                .multilineTextAlignment(.leading)
            Spacer()
        }
        .foregroundColor(.white)
        .padding(12)
        .background(type.color.opacity(0.85))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct LoadingOverlay: View {
    let message: String

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.3)
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
        }
    }
}
