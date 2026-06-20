import UIKit

enum Haptics {
    static func play(_ event: HapticEvent) {
        switch event {
        case .magnetPickup:
            UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.6)
        case .magnetDrop:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.7)
        case .pulseCharge:
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.5)
        case .blockImpact:
            UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.72)
        case .targetLock:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .puzzleSolved:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .invalidMove:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }
    }
}
