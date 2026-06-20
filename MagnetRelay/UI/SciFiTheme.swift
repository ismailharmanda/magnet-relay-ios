import SwiftUI
import UIKit

enum SciFiTheme {
    static let labBlack = Color(red: 0.025, green: 0.032, blue: 0.045)
    static let panel = Color(red: 0.075, green: 0.088, blue: 0.11)
    static let panelStroke = Color(red: 0.22, green: 0.34, blue: 0.38)
    static let cyan = Color(red: 0.10, green: 0.78, blue: 0.92)
    static let amber = Color(red: 1.0, green: 0.68, blue: 0.18)
    static let violet = Color(red: 0.68, green: 0.42, blue: 1.0)
    static let crimson = Color(red: 1.0, green: 0.25, blue: 0.32)
    static let green = Color(red: 0.26, green: 0.90, blue: 0.55)
    static let text = Color(red: 0.92, green: 0.97, blue: 1.0)
    static let muted = Color(red: 0.58, green: 0.68, blue: 0.72)

    static func swiftUIColor(for polarity: ChargePolarity) -> Color {
        switch polarity {
        case .cyan: cyan
        case .amber: amber
        case .violet: violet
        }
    }

    static func uiColor(for polarity: ChargePolarity) -> UIColor {
        switch polarity {
        case .cyan: UIColor(red: 0.10, green: 0.78, blue: 0.92, alpha: 1)
        case .amber: UIColor(red: 1.0, green: 0.68, blue: 0.18, alpha: 1)
        case .violet: UIColor(red: 0.68, green: 0.42, blue: 1.0, alpha: 1)
        }
    }

    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.020, green: 0.026, blue: 0.038),
                Color(red: 0.055, green: 0.070, blue: 0.082),
                Color(red: 0.038, green: 0.026, blue: 0.048)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct InstrumentPanel<Content: View>: View {
    var padding: CGFloat = 14
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(SciFiTheme.panel.opacity(0.88))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(SciFiTheme.panelStroke.opacity(0.8), lineWidth: 1)
                    )
                    .shadow(color: SciFiTheme.cyan.opacity(0.12), radius: 14, y: 8)
            )
    }
}

struct PolarityDot: View {
    var polarity: ChargePolarity
    var size: CGFloat = 10

    var body: some View {
        Circle()
            .fill(SciFiTheme.swiftUIColor(for: polarity))
            .frame(width: size, height: size)
            .shadow(color: SciFiTheme.swiftUIColor(for: polarity).opacity(0.75), radius: 8)
    }
}
