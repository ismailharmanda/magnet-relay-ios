import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
    private let progressStore: ProgressStore
    let monetizationHooks = MonetizationHooks()

    var progress: ProgressState

    init(progressStore: ProgressStore = ProgressStore()) {
        self.progressStore = progressStore
        progress = progressStore.state
    }

    func complete(levelID: Int) {
        progressStore.complete(levelID: levelID)
        progress = progressStore.state

        if levelID > 1, levelID.isMultiple(of: 3), !progress.noAdsUnlocked {
            recordMonetization(.interstitialAfterLevel, levelID: levelID, reason: "Cadence placeholder after solved level.")
        }
    }

    func consumeHintCredit(levelID: Int) -> Bool {
        let didConsume = progressStore.consumeHintCredit()
        progress = progressStore.state
        if !didConsume {
            recordMonetization(.rewardedHint, levelID: levelID, reason: "Out of local hint credits.")
        }
        return didConsume
    }

    func grantRewardedUndo(levelID: Int) {
        recordMonetization(.rewardedUndo, levelID: levelID, reason: "Undo stack empty.")
    }

    func recordRetry(levelID: Int, retryCount: Int) {
        if retryCount > 0, retryCount.isMultiple(of: 3), !progress.noAdsUnlocked {
            recordMonetization(.interstitialAfterRetry, levelID: levelID, reason: "Cadence placeholder after repeated retries.")
        }
    }

    func resetProgress() {
        progressStore.reset()
        progress = progressStore.state
    }

    private func recordMonetization(_ placement: MonetizationPlacement, levelID: Int?, reason: String) {
        monetizationHooks.record(placement, levelID: levelID, reason: reason)
    }
}
