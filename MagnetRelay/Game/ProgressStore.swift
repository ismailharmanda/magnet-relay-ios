import Foundation

struct ProgressState: Codable, Equatable {
    var unlockedLevel: Int
    var completedLevelIDs: Set<Int>
    var hintCredits: Int
    var noAdsUnlocked: Bool

    static let fresh = ProgressState(
        unlockedLevel: 1,
        completedLevelIDs: [],
        hintCredits: 3,
        noAdsUnlocked: false
    )
}

final class ProgressStore {
    static let storageKey = "magnet-relay.progress"

    private let defaults: UserDefaults
    private(set) var state: ProgressState

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode(ProgressState.self, from: data) {
            state = decoded
        } else {
            state = .fresh
        }
    }

    func complete(levelID: Int) {
        state.completedLevelIDs.insert(levelID)
        state.unlockedLevel = max(state.unlockedLevel, min(levelID + 1, LevelCatalog.levels.count))
        save()
    }

    @discardableResult
    func consumeHintCredit() -> Bool {
        guard state.hintCredits > 0 else { return false }
        state.hintCredits -= 1
        save()
        return true
    }

    func grantHintCredit() {
        state.hintCredits += 1
        save()
    }

    func reset() {
        state = .fresh
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }
}
