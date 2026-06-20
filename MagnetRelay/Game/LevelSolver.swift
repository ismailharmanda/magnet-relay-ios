import Foundation

struct PlannedMove: Codable, Equatable, Hashable, CustomStringConvertible {
    var magnetID: String
    var originCell: GridPoint
    var destinationCell: GridPoint
    var pulseMoves: [BlockMove]
    var touchedHazard: Bool

    var description: String {
        let pulseSummary = pulseMoves
            .map { "\($0.blockID): \($0.from)->\($0.to)" }
            .joined(separator: ", ")
        return "\(magnetID) \(originCell)->\(destinationCell) [\(pulseSummary)]"
    }
}

struct SolveReport: Codable, Equatable {
    var levelID: Int
    var solvable: Bool
    var shortestSolution: [PlannedMove]
    var moveCount: Int
    var pulseCount: Int
    var visitedStateCount: Int
    var deadEndCount: Int
    var difficultyScore: Int
    var failureReason: String?
}

enum LevelDifficultyBand: String, Codable, CaseIterable, Comparable {
    case tutorial
    case easy
    case medium
    case hard
    case expert

    static func < (lhs: LevelDifficultyBand, rhs: LevelDifficultyBand) -> Bool {
        guard let lhsIndex = allCases.firstIndex(of: lhs),
              let rhsIndex = allCases.firstIndex(of: rhs)
        else { return false }
        return lhsIndex < rhsIndex
    }

    var minimumSolutionPulses: Int {
        switch self {
        case .tutorial: 1
        case .easy: 2
        case .medium: 4
        case .hard: 5
        case .expert: 7
        }
    }
}

enum MechanicTier: String, Codable, CaseIterable {
    case singlePolarityOpenLanes
    case barriers
    case multiPolarity
    case hazards
    case largerBoards
    case tightMoveBudgets
}

enum LevelSolver {
    struct Configuration: Equatable {
        var maxSolutionActions: Int
        var maxVisitedStates: Int
        var requiresProgressImprovement: Bool

        static let `default` = Configuration(
            maxSolutionActions: 18,
            maxVisitedStates: 80_000,
            requiresProgressImprovement: false
        )

        static func catalog(level: LevelDefinition) -> Configuration {
            Configuration(
                maxSolutionActions: max(18, level.parPulses + 6),
                maxVisitedStates: 120_000,
                requiresProgressImprovement: false
            )
        }

        static func generatedCatalog(level: LevelDefinition) -> Configuration {
            Configuration(
                maxSolutionActions: max(18, level.parPulses + 6),
                maxVisitedStates: 120_000,
                requiresProgressImprovement: true
            )
        }
    }

    static func solve(level: LevelDefinition, configuration: Configuration = .default) -> SolveReport {
        solve(level: level, initialState: GameState(level: level), configuration: configuration)
    }

    static func solve(
        level: LevelDefinition,
        initialState: GameState,
        configuration: Configuration = .default
    ) -> SolveReport {
        if WinValidator.isSolved(level: level, state: initialState) {
            return SolveReport(
                levelID: level.id,
                solvable: true,
                shortestSolution: [],
                moveCount: 0,
                pulseCount: 0,
                visitedStateCount: 1,
                deadEndCount: 0,
                difficultyScore: 0,
                failureReason: nil
            )
        }
        if let greedySolution = greedyCurrentCellSolution(level: level, initialState: initialState, configuration: configuration) {
            return solvedReport(
                level: level,
                solution: greedySolution,
                visitedCount: greedySolution.count + 1,
                deadEndCount: 0
            )
        }

        var frontier = [PrioritizedSearchNode(
            state: initialState.normalizedForSolving(),
            path: [],
            priority: heuristic(level: level, state: initialState),
            heuristic: heuristic(level: level, state: initialState),
            sequence: 0
        )]
        var bestCostByState = [SolverStateKey(state: initialState): 0]
        var visitedCount = 1
        var deadEnds = 0
        var sequence = 1
        var hitVisitedLimit = false

        while !frontier.isEmpty {
            let bestIndex = frontier.indices.min { lhs, rhs in
                let left = frontier[lhs]
                let right = frontier[rhs]
                if left.priority != right.priority { return left.priority < right.priority }
                if left.heuristic != right.heuristic { return left.heuristic < right.heuristic }
                return left.sequence < right.sequence
            }!
            let node = frontier.remove(at: bestIndex)

            guard node.path.count < configuration.maxSolutionActions else {
                deadEnds += 1
                continue
            }

            var expanded = false
            for transition in legalTransitions(from: node.state, level: level, configuration: configuration) where !transition.state.failed {
                let nextCost = node.path.count + 1
                let key = SolverStateKey(state: transition.state)
                if let bestCost = bestCostByState[key], bestCost <= nextCost {
                    continue
                }
                bestCostByState[key] = nextCost
                visitedCount += 1
                if visitedCount > configuration.maxVisitedStates {
                    hitVisitedLimit = true
                    frontier.removeAll()
                    break
                }

                expanded = true
                let nextPath = node.path + [transition.move]
                if WinValidator.isSolved(level: level, state: transition.state) {
                    return solvedReport(
                        level: level,
                        solution: nextPath,
                        visitedCount: visitedCount,
                        deadEndCount: deadEnds
                    )
                }

                let nextHeuristic = heuristic(level: level, state: transition.state)
                frontier.append(PrioritizedSearchNode(
                    state: transition.state.normalizedForSolving(),
                    path: nextPath,
                    priority: nextCost + nextHeuristic,
                    heuristic: nextHeuristic,
                    sequence: sequence
                ))
                sequence += 1
            }

            if !expanded {
                deadEnds += 1
            }
        }

        return SolveReport(
            levelID: level.id,
            solvable: false,
            shortestSolution: [],
            moveCount: 0,
            pulseCount: 0,
            visitedStateCount: visitedCount,
            deadEndCount: deadEnds,
            difficultyScore: unsolvedDifficultyScore(
                level: level,
                visitedCount: visitedCount,
                deadEndCount: deadEnds
            ),
            failureReason: hitVisitedLimit ? "visited-state-limit" : "no-solution"
        )
    }

    static func replay(level: LevelDefinition, plannedMoves: [PlannedMove]) -> SolveReport {
        var state = GameState(level: level)
        var actualMoves: [PlannedMove] = []

        for plannedMove in plannedMoves {
            guard let origin = state.magnets[plannedMove.magnetID] else {
                return replayFailure(level: level, moves: actualMoves, reason: "missing-magnet-\(plannedMove.magnetID)")
            }

            let relocation = MagnetRuleEngine.relocateMagnet(
                plannedMove.magnetID,
                to: plannedMove.destinationCell,
                level: level,
                state: &state
            )
            guard case .success = relocation else {
                return replayFailure(level: level, moves: actualMoves, reason: "illegal-magnet-drop")
            }
            state.undoStack.removeAll()

            let pulse = MagnetRuleEngine.planPulse(magnetID: plannedMove.magnetID, level: level, state: state)
            MagnetRuleEngine.applyPulse(pulse, level: level, state: &state)
            state.undoStack.removeAll()

            actualMoves.append(PlannedMove(
                magnetID: plannedMove.magnetID,
                originCell: origin,
                destinationCell: plannedMove.destinationCell,
                pulseMoves: pulse.moves,
                touchedHazard: pulse.touchedHazard
            ))

            if state.failed {
                return replayFailure(level: level, moves: actualMoves, reason: "hazard-touched")
            }
            if WinValidator.isSolved(level: level, state: state) {
                return solvedReport(
                    level: level,
                    solution: actualMoves,
                    visitedCount: actualMoves.count + 1,
                    deadEndCount: 0
                )
            }
        }

        if WinValidator.isSolved(level: level, state: state) {
            return solvedReport(
                level: level,
                solution: actualMoves,
                visitedCount: actualMoves.count + 1,
                deadEndCount: 0
            )
        }

        return replayFailure(level: level, moves: actualMoves, reason: "script-ended-unsolved")
    }

    private static func greedyCurrentCellSolution(
        level: LevelDefinition,
        initialState: GameState,
        configuration: Configuration
    ) -> [PlannedMove]? {
        var state = initialState.normalizedForSolving()
        var solution: [PlannedMove] = []

        while solution.count < configuration.maxSolutionActions {
            let currentProgress = progressScore(level: level, state: state)
            let candidates = legalTransitions(from: state, level: level, configuration: configuration)
                .filter { transition in
                    transition.move.originCell == transition.move.destinationCell
                        && !transition.state.failed
                        && progressScore(level: level, state: transition.state) < currentProgress
                }
                .sorted { lhs, rhs in
                    let lhsProgress = progressScore(level: level, state: lhs.state)
                    let rhsProgress = progressScore(level: level, state: rhs.state)
                    if lhsProgress != rhsProgress { return lhsProgress < rhsProgress }
                    let lhsHeuristic = heuristic(level: level, state: lhs.state)
                    let rhsHeuristic = heuristic(level: level, state: rhs.state)
                    if lhsHeuristic != rhsHeuristic { return lhsHeuristic < rhsHeuristic }
                    if lhs.move.pulseMoves.count != rhs.move.pulseMoves.count {
                        return lhs.move.pulseMoves.count > rhs.move.pulseMoves.count
                    }
                    return lhs.move.magnetID < rhs.move.magnetID
                }

            guard let next = candidates.first else { return nil }
            solution.append(next.move)
            state = next.state.normalizedForSolving()
            if WinValidator.isSolved(level: level, state: state) {
                return solution
            }
        }

        return nil
    }

    private static func depthLimitedSearch(
        state: GameState,
        path: [PlannedMove],
        depthLimit: Int,
        level: LevelDefinition,
        configuration: Configuration,
        bestDepthByState: inout [SolverStateKey: Int],
        stats: inout SearchStats
    ) -> [PlannedMove]? {
        if WinValidator.isSolved(level: level, state: state) {
            return path
        }
        guard path.count < depthLimit else {
            stats.deadEndCount += 1
            return nil
        }

        let transitions = legalTransitions(from: state, level: level, configuration: configuration)
        var expanded = false
        for transition in transitions where !transition.state.failed {
            let key = SolverStateKey(state: transition.state)
            let nextDepth = path.count + 1
            if let previousDepth = bestDepthByState[key], previousDepth <= nextDepth {
                continue
            }

            expanded = true
            bestDepthByState[key] = nextDepth
            stats.visitedStateCount += 1
            if stats.visitedStateCount > configuration.maxVisitedStates {
                stats.hitVisitedLimit = true
                return nil
            }

            let nextPath = path + [transition.move]
            if WinValidator.isSolved(level: level, state: transition.state) {
                return nextPath
            }
            if let found = depthLimitedSearch(
                state: transition.state.normalizedForSolving(),
                path: nextPath,
                depthLimit: depthLimit,
                level: level,
                configuration: configuration,
                bestDepthByState: &bestDepthByState,
                stats: &stats
            ) {
                return found
            }
        }

        if !expanded {
            stats.deadEndCount += 1
        }
        return nil
    }

    private static func solvedReport(
        level: LevelDefinition,
        solution: [PlannedMove],
        visitedCount: Int,
        deadEndCount: Int
    ) -> SolveReport {
        let moveCount = solution.filter { $0.originCell != $0.destinationCell }.count
        let pulseCount = solution.count
        return SolveReport(
            levelID: level.id,
            solvable: true,
            shortestSolution: solution,
            moveCount: moveCount,
            pulseCount: pulseCount,
            visitedStateCount: visitedCount,
            deadEndCount: deadEndCount,
            difficultyScore: difficultyScore(
                level: level,
                solution: solution,
                visitedCount: visitedCount,
                deadEndCount: deadEndCount
            ),
            failureReason: nil
        )
    }

    private static func replayFailure(level: LevelDefinition, moves: [PlannedMove], reason: String) -> SolveReport {
        SolveReport(
            levelID: level.id,
            solvable: false,
            shortestSolution: moves,
            moveCount: moves.filter { $0.originCell != $0.destinationCell }.count,
            pulseCount: moves.count,
            visitedStateCount: moves.count + 1,
            deadEndCount: 1,
            difficultyScore: unsolvedDifficultyScore(level: level, visitedCount: moves.count + 1, deadEndCount: 1),
            failureReason: reason
        )
    }

    private static func legalTransitions(
        from state: GameState,
        level: LevelDefinition,
        configuration: Configuration
    ) -> [Transition] {
        level.magnets
            .filter(\.movable)
            .sorted { $0.id < $1.id }
            .flatMap { magnet in
                orderedDestinations(for: magnet, state: state, level: level, configuration: configuration).compactMap { destination -> Transition? in
                    guard let origin = state.magnets[magnet.id] else { return nil }
                    var next = state.normalizedForSolving()
                    let relocation = MagnetRuleEngine.relocateMagnet(magnet.id, to: destination, level: level, state: &next)
                    guard case .success = relocation else { return nil }
                    next.undoStack.removeAll()

                    let pulse = MagnetRuleEngine.planPulse(magnetID: magnet.id, level: level, state: next)
                    let moved = MagnetRuleEngine.applyPulse(pulse, level: level, state: &next)
                    next.undoStack.removeAll()

                    if !moved, !WinValidator.isSolved(level: level, state: next) {
                        return nil
                    }
                    if configuration.requiresProgressImprovement,
                       !WinValidator.isSolved(level: level, state: next),
                       progressScore(level: level, state: next) >= progressScore(level: level, state: state) {
                        return nil
                    }

                    let planned = PlannedMove(
                        magnetID: magnet.id,
                        originCell: origin,
                        destinationCell: destination,
                        pulseMoves: pulse.moves,
                        touchedHazard: pulse.touchedHazard
                    )
                    return Transition(state: next.normalizedForSolving(), move: planned)
                }
            }
            .sorted { lhs, rhs in
                let lhsPriority = transitionPriority(lhs.move)
                let rhsPriority = transitionPriority(rhs.move)
                if lhsPriority != rhsPriority { return lhsPriority > rhsPriority }
                if lhs.move.magnetID != rhs.move.magnetID { return lhs.move.magnetID < rhs.move.magnetID }
                if lhs.move.destinationCell.y != rhs.move.destinationCell.y {
                    return lhs.move.destinationCell.y < rhs.move.destinationCell.y
                }
                return lhs.move.destinationCell.x < rhs.move.destinationCell.x
            }
    }

    private static func transitionPriority(_ move: PlannedMove) -> Int {
        let sameCellPulse = move.originCell == move.destinationCell ? 1_000 : 0
        let motion = move.pulseMoves.count * 120
        let repositionCost = move.originCell.manhattanDistance(to: move.destinationCell)
        return sameCellPulse + motion - repositionCost
    }

    private static func heuristic(level: LevelDefinition, state: GameState) -> Int {
        level.targets.map { target in
            level.blocks
                .filter { $0.polarity == target.polarity }
                .compactMap { block in
                    state.blocks[block.id]?.manhattanDistance(to: target.position)
                }
                .min() ?? level.columns + level.rows
        }.max() ?? 0
    }

    private static func progressScore(level: LevelDefinition, state: GameState) -> Int {
        level.targets.map { target in
            level.blocks
                .filter { $0.polarity == target.polarity }
                .compactMap { block in
                    state.blocks[block.id]?.manhattanDistance(to: target.position)
                }
                .min() ?? level.columns + level.rows
        }.reduce(0, +)
    }

    private static func orderedDestinations(
        for magnet: MagnetDefinition,
        state: GameState,
        level: LevelDefinition,
        configuration: Configuration
    ) -> [GridPoint] {
        guard let current = state.magnets[magnet.id] else { return [] }
        let usefulCells = level.gridCells.filter { cell in
            guard case .success = MagnetRuleEngine.canPlaceMagnet(magnet.id, at: cell, level: level, state: state) else {
                return false
            }
            if cell == current { return true }
            if configuration.requiresProgressImprovement {
                return canPullMatchingBlockTowardTarget(magnet: magnet, from: cell, state: state, level: level)
            }
            return canInfluenceMatchingBlock(magnet: magnet, from: cell, state: state, level: level)
        }

        return usefulCells.sorted { lhs, rhs in
            if lhs == current { return true }
            if rhs == current { return false }
            let lhsDistance = lhs.manhattanDistance(to: current)
            let rhsDistance = rhs.manhattanDistance(to: current)
            if lhsDistance != rhsDistance { return lhsDistance < rhsDistance }
            if lhs.y != rhs.y { return lhs.y < rhs.y }
            return lhs.x < rhs.x
        }
    }

    private static func canInfluenceMatchingBlock(
        magnet: MagnetDefinition,
        from cell: GridPoint,
        state: GameState,
        level: LevelDefinition
    ) -> Bool {
        level.blocks.contains { block in
            guard block.polarity == magnet.polarity,
                  let blockCell = state.blocks[block.id],
                  blockCell != cell,
                  blockCell.manhattanDistance(to: cell) <= PhysicsTuning.premiumSlice.magneticRange,
                  blockCell.isOrthogonallyAligned(with: cell),
                  MagnetRuleEngine.hasLineOfSight(from: blockCell, to: cell, level: level)
            else { return false }
            let destination = blockCell.step(toward: cell)
            return destination != cell
        }
    }

    private static func canPullMatchingBlockTowardTarget(
        magnet: MagnetDefinition,
        from cell: GridPoint,
        state: GameState,
        level: LevelDefinition
    ) -> Bool {
        level.blocks.contains { block in
            guard block.polarity == magnet.polarity,
                  let blockCell = state.blocks[block.id],
                  blockCell != cell,
                  blockCell.manhattanDistance(to: cell) <= PhysicsTuning.premiumSlice.magneticRange,
                  blockCell.isOrthogonallyAligned(with: cell),
                  MagnetRuleEngine.hasLineOfSight(from: blockCell, to: cell, level: level)
            else { return false }

            let destination = blockCell.step(toward: cell)
            guard destination != cell else { return false }

            return level.targets.contains { target in
                guard target.polarity == magnet.polarity,
                      blockCell != target.position,
                      blockCell.isOrthogonallyAligned(with: target.position),
                      target.position.isOrthogonallyAligned(with: cell),
                      blockCell.step(toward: target.position) == destination,
                      blockCell.manhattanDistance(to: cell) > blockCell.manhattanDistance(to: target.position),
                      MagnetRuleEngine.hasLineOfSight(from: blockCell, to: target.position, level: level)
                else { return false }
                return true
            }
        }
    }

    private static func difficultyScore(
        level: LevelDefinition,
        solution: [PlannedMove],
        visitedCount: Int,
        deadEndCount: Int
    ) -> Int {
        let polarities = Set(level.blocks.map(\.polarity)).count
        let pulseMotion = solution.flatMap(\.pulseMoves).count
        let mechanics =
            level.barriers.count * 2
            + level.hazards.count * 5
            + max(0, polarities - 1) * 12
            + max(0, level.columns * level.rows - 42) / 3
        let pressure = max(0, solution.count - level.parPulses) * 4
        return solution.count * 11
            + pulseMotion * 3
            + mechanics
            + min(visitedCount / 35, 35)
            + min(deadEndCount / 10, 18)
            + pressure
    }

    private static func unsolvedDifficultyScore(level: LevelDefinition, visitedCount: Int, deadEndCount: Int) -> Int {
        300
            + level.columns * level.rows
            + level.barriers.count * 3
            + level.hazards.count * 6
            + min(visitedCount / 20, 80)
            + min(deadEndCount / 8, 60)
    }
}

private struct Transition {
    var state: GameState
    var move: PlannedMove
}

private struct PrioritizedSearchNode {
    var state: GameState
    var path: [PlannedMove]
    var priority: Int
    var heuristic: Int
    var sequence: Int
}

private struct SearchStats {
    var visitedStateCount: Int
    var deadEndCount: Int
    var hitVisitedLimit: Bool
}

private struct SolverStateKey: Hashable {
    var magnets: [PlacedCell]
    var blocks: [PlacedCell]

    init(state: GameState) {
        magnets = state.magnets
            .map { PlacedCell(id: $0.key, cell: $0.value) }
            .sorted()
        blocks = state.blocks
            .map { PlacedCell(id: $0.key, cell: $0.value) }
            .sorted()
    }
}

private struct PlacedCell: Hashable, Comparable {
    var id: String
    var cell: GridPoint

    static func < (lhs: PlacedCell, rhs: PlacedCell) -> Bool {
        if lhs.id != rhs.id { return lhs.id < rhs.id }
        if lhs.cell.y != rhs.cell.y { return lhs.cell.y < rhs.cell.y }
        return lhs.cell.x < rhs.cell.x
    }
}

private extension GameState {
    func normalizedForSolving() -> GameState {
        var copy = self
        copy.undoStack.removeAll()
        return copy
    }
}
