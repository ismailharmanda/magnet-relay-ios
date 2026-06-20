import Foundation
import Observation
import SpriteKit

struct LevelCompletionPresentation: Identifiable, Equatable {
    let id: String
    let levelID: Int
    let labCode: String
    let title: String
    let moves: Int
    let pulses: Int
    let parPulses: Int
    let nextLevelID: Int?
    let nextLabCode: String?

    var hasNextLevel: Bool {
        nextLevelID != nil
    }

    init(level: LevelDefinition, state: GameState) {
        let nextLevel = level.id < LevelCatalog.levels.count ? LevelCatalog.level(id: level.id + 1) : nil
        self.id = "level-complete-\(level.id)-\(state.moves)-\(state.pulses)"
        levelID = level.id
        labCode = level.labCode
        title = level.title
        moves = state.moves
        pulses = state.pulses
        parPulses = level.parPulses
        nextLevelID = nextLevel?.id
        nextLabCode = nextLevel?.labCode
    }
}

@MainActor
@Observable
final class GameController {
    var level: LevelDefinition
    var scene: MagnetGameScene
    var state: GameState
    var completion: LevelCompletionPresentation?
    var message: String?
    var showsHint = false
    var debugLevelID: Int
    var slowMotionEnabled = false
    var hitboxesVisible = false
    var magneticForceMultiplier = 1.0

    private weak var appModel: AppModel?

    init(level: LevelDefinition) {
        self.level = level
        scene = MagnetGameScene(size: CGSize(width: 390, height: 760), level: level)
        state = GameState(level: level)
        debugLevelID = level.id
        wireSceneCallbacks()
    }

    func bind(appModel: AppModel) {
        self.appModel = appModel
    }

    func load(level newLevel: LevelDefinition) {
        level = newLevel
        debugLevelID = newLevel.id
        scene = MagnetGameScene(size: scene.size, level: newLevel)
        state = GameState(level: newLevel)
        completion = nil
        wireSceneCallbacks()
        message = nil
        showsHint = false
        scene.setSlowMotion(slowMotionEnabled)
        scene.setHitboxesVisible(hitboxesVisible)
        scene.setForceMultiplier(magneticForceMultiplier)
    }

    func undo() {
        completion = nil
        if scene.undo() {
            message = "Undone."
        } else {
            appModel?.grantRewardedUndo(levelID: level.id)
            message = "No undo yet."
        }
    }

    func reset() {
        completion = nil
        scene.resetLevel()
        state = sceneState()
        appModel?.recordRetry(levelID: level.id, retryCount: state.retries)
        message = "Reset."
    }

    func hint() {
        guard let appModel else { return }
        if appModel.consumeHintCredit(levelID: level.id) {
            showsHint = true
            scene.showHintPulse()
            message = level.hint
        } else {
            message = "No hints left."
        }
    }

    func nextLevel() {
        let nextID = min(level.id + 1, LevelCatalog.levels.count)
        load(level: LevelCatalog.level(id: nextID))
    }

    func advanceFromCompletion() {
        guard let completion else { return }
        if let nextLevelID = completion.nextLevelID {
            load(level: LevelCatalog.level(id: nextLevelID))
        } else {
            load(level: level)
        }
    }

    func showSolvedPreview() {
        scene.showSolvedPreview()
        state = scene.gameState
        message = "Solved."
    }

    func showCompletionPreview() {
        scene.showSolvedPreview()
        presentCompletion(for: scene.gameState, markProgress: false)
    }

    func setSlowMotion(_ enabled: Bool) {
        slowMotionEnabled = enabled
        scene.setSlowMotion(enabled)
    }

    func setHitboxesVisible(_ visible: Bool) {
        hitboxesVisible = visible
        scene.setHitboxesVisible(visible)
    }

    func setMagneticForceMultiplier(_ value: Double) {
        magneticForceMultiplier = value
        scene.setForceMultiplier(value)
    }

    private func wireSceneCallbacks() {
        scene.onStateChanged = { [weak self] newState in
            self?.state = newState
        }
        scene.onSolved = { [weak self] solvedState in
            guard let self else { return }
            presentCompletion(for: solvedState, markProgress: true)
        }
        scene.onRetry = { [weak self] newState in
            self?.completion = nil
            self?.state = newState
        }
    }

    private func presentCompletion(for solvedState: GameState, markProgress: Bool) {
        guard solvedState.solved else { return }
        state = solvedState
        if markProgress {
            appModel?.complete(levelID: level.id)
        }
        completion = LevelCompletionPresentation(level: level, state: solvedState)
        message = nil
    }

    private func sceneState() -> GameState {
        state
    }
}
