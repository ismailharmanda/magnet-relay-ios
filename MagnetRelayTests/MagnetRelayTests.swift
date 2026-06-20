import CoreGraphics
import XCTest
@testable import MagnetRelay

final class MagnetRelayTests: XCTestCase {
    func testSplashPolicyShowsOnlyForDefaultLaunch() {
        XCTAssertTrue(LaunchSplashPolicy.shouldShowSplash(for: ["MagnetRelay"]))
        XCTAssertFalse(LaunchSplashPolicy.shouldShowSplash(for: ["MagnetRelay", "-MagnetRelaySkipSplash"]))
        XCTAssertFalse(LaunchSplashPolicy.shouldShowSplash(for: ["MagnetRelay", "-MagnetRelayLevelsPreview"]))
        XCTAssertFalse(LaunchSplashPolicy.shouldShowSplash(for: ["MagnetRelay", "-MagnetRelaySettingsPreview"]))
        XCTAssertFalse(LaunchSplashPolicy.shouldShowSplash(for: ["MagnetRelay", "-MagnetRelayGamePreview"]))
        XCTAssertFalse(LaunchSplashPolicy.shouldShowSplash(for: ["MagnetRelay", "-MagnetRelaySolvedPreview"]))
        XCTAssertFalse(LaunchSplashPolicy.shouldShowSplash(for: ["MagnetRelay", "-MagnetRelayCompletionPreview"]))
    }

    func testCatalogProvidesPremiumSliceDepth() {
        XCTAssertEqual(LevelCatalog.handcraftedLevels.count, 12)
        XCTAssertEqual(LevelCatalog.levels.count, 212)
        XCTAssertEqual(LevelCatalog.levels.prefix(12).map(\.labCode), (1...12).map { String(format: "MR-%02d", $0) })
        XCTAssertTrue(LevelCatalog.levels.allSatisfy { !$0.magnets.isEmpty && !$0.blocks.isEmpty && !$0.targets.isEmpty })
    }

    func testMagnetPulsePullsMatchingBlockOneCell() throws {
        let level = LevelCatalog.level(id: 1)
        var state = GameState(level: level)

        let resolution = MagnetRuleEngine.planPulse(magnetID: "m-cyan", level: level, state: state)

        XCTAssertEqual(resolution.moves, [
            BlockMove(blockID: "b-cyan", from: GridPoint(x: 4, y: 3), to: GridPoint(x: 3, y: 3), polarity: .cyan)
        ])
        MagnetRuleEngine.applyPulse(resolution, level: level, state: &state)
        XCTAssertEqual(state.blocks["b-cyan"], GridPoint(x: 3, y: 3))
        XCTAssertFalse(state.solved)

        let second = MagnetRuleEngine.planPulse(magnetID: "m-cyan", level: level, state: state)
        MagnetRuleEngine.applyPulse(second, level: level, state: &state)
        XCTAssertEqual(state.blocks["b-cyan"], GridPoint(x: 2, y: 3))
        XCTAssertTrue(state.solved)
    }

    func testLineOfSightStopsAtBarrier() {
        let level = LevelDefinition(
            id: 99,
            title: "Barrier Test",
            labCode: "TEST",
            columns: 5,
            rows: 5,
            parPulses: 1,
            magnets: [MagnetDefinition(id: "m", position: GridPoint(x: 0, y: 2), polarity: .cyan, movable: true)],
            blocks: [BlockDefinition(id: "b", position: GridPoint(x: 4, y: 2), polarity: .cyan, mass: 1)],
            targets: [TargetDefinition(id: "t", position: GridPoint(x: 3, y: 2), polarity: .cyan)],
            barriers: [GridPoint(x: 2, y: 2)],
            emitters: [],
            hazards: [],
            hint: ""
        )
        let state = GameState(level: level)
        let resolution = MagnetRuleEngine.planPulse(magnetID: "m", level: level, state: state)
        XCTAssertTrue(resolution.moves.isEmpty)
    }

    func testSnapLogicAcceptsNearGridCellAndRejectsFarDrop() throws {
        let level = LevelCatalog.level(id: 1)
        let origin = CGPoint(x: 20, y: 30)
        let tileSize: CGFloat = 50

        let near = try XCTUnwrap(SnapLogic.snap(
            worldPosition: CGPoint(x: 20 + 2 * 50 + 4, y: 30 + 3 * 50 - 3),
            boardOrigin: origin,
            tileSize: tileSize,
            level: level
        ))
        XCTAssertEqual(near.cell, GridPoint(x: 2, y: 3))
        XCTAssertTrue(near.accepted)

        let far = try XCTUnwrap(SnapLogic.snap(
            worldPosition: CGPoint(x: 20 + 2 * 50 + 24, y: 30 + 3 * 50 + 24),
            boardOrigin: origin,
            tileSize: tileSize,
            level: level
        ))
        XCTAssertEqual(far.cell, GridPoint(x: 2, y: 3))
        XCTAssertFalse(far.accepted)
    }

    func testWinValidationRequiresMatchingPolarityOnTargets() {
        let level = LevelDefinition(
            id: 100,
            title: "Win Test",
            labCode: "TEST",
            columns: 4,
            rows: 4,
            parPulses: 1,
            magnets: [MagnetDefinition(id: "m", position: GridPoint(x: 0, y: 0), polarity: .cyan, movable: true)],
            blocks: [
                BlockDefinition(id: "cyan", position: GridPoint(x: 1, y: 1), polarity: .cyan, mass: 1),
                BlockDefinition(id: "amber", position: GridPoint(x: 2, y: 2), polarity: .amber, mass: 1)
            ],
            targets: [
                TargetDefinition(id: "target", position: GridPoint(x: 1, y: 1), polarity: .cyan)
            ],
            barriers: [],
            emitters: [],
            hazards: [],
            hint: ""
        )
        var state = GameState(level: level)
        XCTAssertTrue(WinValidator.isSolved(level: level, state: state))

        state.blocks["cyan"] = GridPoint(x: 0, y: 1)
        state.blocks["amber"] = GridPoint(x: 1, y: 1)
        XCTAssertFalse(WinValidator.isSolved(level: level, state: state))
    }

    func testUndoRestoresFullSnapshotAfterPulseAndMagnetMove() throws {
        let level = LevelCatalog.level(id: 1)
        var state = GameState(level: level)
        let relocation = MagnetRuleEngine.relocateMagnet("m-cyan", to: GridPoint(x: 0, y: 3), level: level, state: &state)
        guard case .success = relocation else {
            return XCTFail("Expected relocation to succeed")
        }
        let afterMove = state
        let resolution = MagnetRuleEngine.planPulse(magnetID: "m-cyan", level: level, state: state)
        MagnetRuleEngine.applyPulse(resolution, level: level, state: &state)

        XCTAssertNotEqual(state.blocks, afterMove.blocks)
        XCTAssertTrue(state.restoreUndoSnapshot())
        XCTAssertEqual(state, afterMove)
    }

    func testMagnetForceVectorPointsTowardMagnetAndScalesWithDistance() {
        let near = MagnetForceResolver.forceVector(
            from: GridPoint(x: 4, y: 3),
            toward: GridPoint(x: 2, y: 3),
            polarityMatches: true
        )
        let far = MagnetForceResolver.forceVector(
            from: GridPoint(x: 6, y: 3),
            toward: GridPoint(x: 2, y: 3),
            polarityMatches: true
        )
        XCTAssertLessThan(near.dx, 0)
        XCTAssertEqual(near.dy, 0, accuracy: 0.001)
        XCTAssertGreaterThan(abs(near.dx), abs(far.dx))

        let mismatch = MagnetForceResolver.forceVector(
            from: GridPoint(x: 4, y: 3),
            toward: GridPoint(x: 2, y: 3),
            polarityMatches: false
        )
        XCTAssertEqual(mismatch, .zero)
    }

    func testRepresentativePulseSimulationIsDeterministic() {
        let level = LevelCatalog.level(id: 10)
        var first = GameState(level: level)
        var second = GameState(level: level)
        let sequence = ["m-cyan", "m-cyan", "m-amber", "m-violet", "m-violet"]

        for magnetID in sequence {
            MagnetRuleEngine.applyPulse(
                MagnetRuleEngine.planPulse(magnetID: magnetID, level: level, state: first),
                level: level,
                state: &first
            )
            MagnetRuleEngine.applyPulse(
                MagnetRuleEngine.planPulse(magnetID: magnetID, level: level, state: second),
                level: level,
                state: &second
            )
        }

        XCTAssertEqual(first.blocks, second.blocks)
        XCTAssertEqual(first.pulses, second.pulses)
        XCTAssertEqual(first.solved, second.solved)
    }

    func testDraggingMagnetCannotDisplaceBlocksBeforeDrop() throws {
        let scene = MagnetGameScene(size: CGSize(width: 390, height: 844), level: LevelCatalog.level(id: 1))
        scene.debugRebuildForTesting()

        let originalBlocks = scene.gameState.blocks
        let originalBlockPosition = try XCTUnwrap(scene.debugBlockPosition(id: "b-cyan"))

        XCTAssertTrue(scene.debugBeginDrag(magnetID: "m-cyan"))
        let draggingPhysics = try XCTUnwrap(scene.debugMagnetPhysics(id: "m-cyan"))
        XCTAssertFalse(draggingPhysics.isDynamic)
        XCTAssertEqual(draggingPhysics.collisionBitMask, 0)
        XCTAssertEqual(draggingPhysics.contactTestBitMask, 0)

        scene.debugMoveSelectedMagnet(to: GridPoint(x: 4, y: 3))

        XCTAssertEqual(scene.gameState.blocks, originalBlocks)
        let blockPositionDuringDrag = try XCTUnwrap(scene.debugBlockPosition(id: "b-cyan"))
        XCTAssertEqual(blockPositionDuringDrag.x, originalBlockPosition.x, accuracy: 0.001)
        XCTAssertEqual(blockPositionDuringDrag.y, originalBlockPosition.y, accuracy: 0.001)

        scene.debugCancelDragForTesting()
        let restoredPhysics = try XCTUnwrap(scene.debugMagnetPhysics(id: "m-cyan"))
        XCTAssertTrue(restoredPhysics.isDynamic)
        XCTAssertEqual(restoredPhysics.collisionBitMask, CollisionCategory.block | CollisionCategory.barrier)
    }

    func testLevelSolverSolvesEveryCatalogLevelAndGeneratedCampaignGates() {
        let reports = LevelCatalog.levels.map { level in
            LevelSolver.solve(level: level, configuration: solveConfiguration(for: level))
        }
        let failures = reports.filter { !$0.solvable }
        XCTAssertTrue(
            failures.isEmpty,
                failures.map { "MR-\($0.levelID): \($0.failureReason ?? "unknown") visited=\($0.visitedStateCount)" }.joined(separator: "\n")
        )

        let reportsByLevelID = Dictionary(uniqueKeysWithValues: reports.map { ($0.levelID, $0) })
        let generated = Array(LevelCatalog.levels.dropFirst(LevelCatalog.handcraftedLevels.count))
        var gateFailures: [String] = []

        for (index, level) in generated.enumerated() {
            let ordinal = index + 1
            guard let report = reportsByLevelID[level.id] else {
                gateFailures.append("\(level.labCode): missing solve report")
                continue
            }

            let minMoveCount = minimumGeneratedMoveCount(for: ordinal)
            if report.moveCount < minMoveCount {
                gateFailures.append("\(level.labCode): moves=\(report.moveCount) expected>=\(minMoveCount)")
            }
            if ordinal > 10, report.moveCount == 0 {
                gateFailures.append("\(level.labCode): zero-move shortcut after onboarding")
            }
            if report.shortestSolution.contains(where: \.touchedHazard) {
                gateFailures.append("\(level.labCode): solution touches hazard")
            }

            let activeMagnets = Set(report.shortestSolution.filter { $0.originCell != $0.destinationCell }.map(\.magnetID)).count
            let polarityCount = Set(level.blocks.map(\.polarity)).count
            switch ordinal {
            case 41...80:
                if level.barriers.isEmpty {
                    gateFailures.append("\(level.labCode): barrier segment without barriers")
                }
            case 81...120:
                if activeMagnets < 2 || polarityCount < 2 {
                    gateFailures.append("\(level.labCode): polarity segment activeMagnets=\(activeMagnets) polarities=\(polarityCount)")
                }
            case 121...160:
                if level.hazards.isEmpty || activeMagnets < 2 || polarityCount < 2 {
                    gateFailures.append("\(level.labCode): hazard segment hazards=\(level.hazards.count) activeMagnets=\(activeMagnets) polarities=\(polarityCount)")
                }
            case 161...200:
                if level.hazards.isEmpty || polarityCount < 3 || activeMagnets < 3 || level.columns != 8 || level.rows != 9 {
                    gateFailures.append("\(level.labCode): expert segment hazards=\(level.hazards.count) activeMagnets=\(activeMagnets) polarities=\(polarityCount) size=\(level.columns)x\(level.rows)")
                }
            default:
                break
            }
        }

        XCTAssertTrue(gateFailures.isEmpty, gateFailures.joined(separator: "\n"))

        let generatedReports = generated.compactMap { reportsByLevelID[$0.id] }
        let moveAverages = segmentAverages(generatedReports.map(\.moveCount))
        let scoreAverages = segmentAverages(generatedReports.map(\.difficultyScore))
        XCTAssertEqual(moveAverages, moveAverages.sorted())
        XCTAssertEqual(scoreAverages, scoreAverages.sorted())
    }

    func testInvalidGeneratedCandidateIsRejected() {
        let invalid = LevelDefinition(
            id: 9_001,
            title: "Blocked Target",
            labCode: "BAD",
            columns: 5,
            rows: 5,
            parPulses: 3,
            magnets: [MagnetDefinition(id: "m", position: GridPoint(x: 0, y: 2), polarity: .cyan, movable: true)],
            blocks: [BlockDefinition(id: "b", position: GridPoint(x: 4, y: 2), polarity: .cyan, mass: 1)],
            targets: [TargetDefinition(id: "t", position: GridPoint(x: 2, y: 2), polarity: .cyan)],
            barriers: [GridPoint(x: 2, y: 2)],
            emitters: [],
            hazards: [],
            hint: ""
        )

        XCTAssertNil(LevelGenerator.validateGeneratedCandidate(
            level: invalid,
            band: .easy,
            mechanicTier: .barriers,
            seed: 99
        ))
    }

    func testSeededGenerationIsDeterministic() {
        let first = LevelGenerator.generate(count: 12, seed: 42)
        let second = LevelGenerator.generate(count: 12, seed: 42)

        XCTAssertEqual(first, second)
        XCTAssertEqual(first.count, 12)
    }

    func testGeneratedBatchIsSolvableAndRampsByDifficultyBand() {
        let generated = Array(LevelCatalog.levels.dropFirst(LevelCatalog.handcraftedLevels.count))

        XCTAssertEqual(generated.count, 200)
        XCTAssertTrue(generated[40..<80].allSatisfy { !$0.barriers.isEmpty })
        XCTAssertTrue(generated[80..<120].allSatisfy { Set($0.blocks.map(\.polarity)).count >= 2 })
        XCTAssertTrue(generated[120..<160].allSatisfy { !$0.hazards.isEmpty })
        XCTAssertTrue(generated[160..<200].allSatisfy {
            !$0.hazards.isEmpty
                && Set($0.blocks.map(\.polarity)).count >= 3
                && $0.columns == 8
                && $0.rows == 9
        })
    }

    func testGeneratedCatalogIDsAndLabCodesAreUniqueAndOrdered() {
        let generated = Array(LevelCatalog.levels.dropFirst(LevelCatalog.handcraftedLevels.count))

        XCTAssertEqual(generated.count, 200)
        XCTAssertEqual(generated.map(\.id), Array(13...212))
        XCTAssertEqual(generated.map(\.labCode), (1...200).map { String(format: "MG-%04d", $0) })
        XCTAssertEqual(Set(LevelCatalog.levels.map(\.id)).count, LevelCatalog.levels.count)
        XCTAssertEqual(Set(LevelCatalog.levels.map(\.labCode)).count, LevelCatalog.levels.count)
    }

    func testProgressPersistenceUnlocksNextLevel() throws {
        let suiteName = "MagnetRelayTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = ProgressStore(defaults: defaults)
        XCTAssertEqual(store.state.unlockedLevel, 1)
        store.complete(levelID: 1)
        XCTAssertEqual(store.state.unlockedLevel, 2)
        XCTAssertTrue(store.state.completedLevelIDs.contains(1))

        for levelID in 2..<LevelCatalog.levels.count {
            store.complete(levelID: levelID)
        }
        XCTAssertEqual(store.state.unlockedLevel, LevelCatalog.levels.count)
        store.complete(levelID: LevelCatalog.levels.count)
        XCTAssertEqual(store.state.unlockedLevel, LevelCatalog.levels.count)

        let reloaded = ProgressStore(defaults: defaults)
        XCTAssertEqual(reloaded.state, store.state)
    }

    @MainActor
    func testCompletionPresentationCreatedFromSolvedPreviewState() throws {
        let controller = GameController(level: LevelCatalog.level(id: 1))

        controller.showCompletionPreview()

        let completion = try XCTUnwrap(controller.completion)
        XCTAssertTrue(controller.state.solved)
        XCTAssertEqual(completion.levelID, 1)
        XCTAssertEqual(completion.labCode, "MR-01")
        XCTAssertEqual(completion.title, LevelCatalog.level(id: 1).title)
        XCTAssertEqual(completion.moves, controller.state.moves)
        XCTAssertEqual(completion.pulses, controller.state.pulses)
        XCTAssertEqual(completion.parPulses, LevelCatalog.level(id: 1).parPulses)
        XCTAssertNil(controller.message)
    }

    @MainActor
    func testCompletionPresentationIncludesNextLevelMetadata() throws {
        let controller = GameController(level: LevelCatalog.level(id: 1))

        controller.showCompletionPreview()

        let completion = try XCTUnwrap(controller.completion)
        XCTAssertEqual(completion.nextLevelID, 2)
        XCTAssertEqual(completion.nextLabCode, "MR-02")
        XCTAssertTrue(completion.hasNextLevel)
    }

    @MainActor
    func testAdvanceFromCompletionLoadsNextLevelAndClearsPresentation() {
        let controller = GameController(level: LevelCatalog.level(id: 1))
        controller.showCompletionPreview()

        controller.advanceFromCompletion()

        XCTAssertEqual(controller.level.id, 2)
        XCTAssertEqual(controller.debugLevelID, 2)
        XCTAssertNil(controller.completion)
        XCTAssertFalse(controller.state.solved)
    }

    @MainActor
    func testFinalLevelCompletionHasNoNextLevelAndReplaysCurrentLevel() throws {
        let finalLevel = LevelCatalog.level(id: LevelCatalog.levels.count)
        let controller = GameController(level: finalLevel)

        controller.showCompletionPreview()

        let completion = try XCTUnwrap(controller.completion)
        XCTAssertNil(completion.nextLevelID)
        XCTAssertNil(completion.nextLabCode)
        XCTAssertFalse(completion.hasNextLevel)

        controller.advanceFromCompletion()

        XCTAssertEqual(controller.level.id, finalLevel.id)
        XCTAssertNil(controller.completion)
        XCTAssertFalse(controller.state.solved)
    }

    private func minimumGeneratedMoveCount(for ordinal: Int) -> Int {
        switch ordinal {
        case 1...10:
            return 0
        case 11...40:
            return 1
        case 41...80:
            return 2
        case 81...120:
            return 2
        case 121...160:
            return 3
        default:
            return 4
        }
    }

    private func segmentAverages(_ values: [Int]) -> [Double] {
        stride(from: 0, to: values.count, by: 40).map { start in
            let segment = values[start..<min(start + 40, values.count)]
            return Double(segment.reduce(0, +)) / Double(segment.count)
        }
    }

    private func solveConfiguration(for level: LevelDefinition) -> LevelSolver.Configuration {
        level.labCode.hasPrefix("MG-") ? .generatedCatalog(level: level) : .catalog(level: level)
    }
}
