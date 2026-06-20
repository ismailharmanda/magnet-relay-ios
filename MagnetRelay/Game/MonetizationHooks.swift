import Foundation

enum MonetizationPlacement: String, CaseIterable, Codable, Identifiable {
    case rewardedHint
    case rewardedUndo
    case interstitialAfterRetry
    case interstitialAfterLevel
    case noAdsPurchase
    case levelPackPurchase

    var id: String { rawValue }

    var title: String {
        switch self {
        case .rewardedHint: "Rewarded Hint"
        case .rewardedUndo: "Rewarded Undo"
        case .interstitialAfterRetry: "Retry Interstitial"
        case .interstitialAfterLevel: "Level Interstitial"
        case .noAdsPurchase: "No Ads"
        case .levelPackPurchase: "Level Pack"
        }
    }
}

struct MonetizationEvent: Codable, Equatable, Identifiable {
    var id = UUID()
    var placement: MonetizationPlacement
    var levelID: Int?
    var reason: String
    var createdAt: Date
}

final class MonetizationHooks {
    private(set) var events: [MonetizationEvent] = []

    func record(_ placement: MonetizationPlacement, levelID: Int?, reason: String) {
        events.append(
            MonetizationEvent(
                placement: placement,
                levelID: levelID,
                reason: reason,
                createdAt: Date()
            )
        )
    }
}
