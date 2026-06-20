import CoreGraphics
import Foundation

enum MagnetRuleError: Error, Equatable {
    case missingMagnet(String)
    case fixedMagnet(String)
    case outsideBoard(GridPoint)
    case occupied(GridPoint)
    case blocked(GridPoint)
}

enum MagnetRuleEngine {
    static func isInside(_ cell: GridPoint, level: LevelDefinition) -> Bool {
        cell.x >= 0 && cell.y >= 0 && cell.x < level.columns && cell.y < level.rows
    }

    static func isBarrier(_ cell: GridPoint, level: LevelDefinition) -> Bool {
        level.barriers.contains(cell)
    }

    static func hasLineOfSight(from start: GridPoint, to end: GridPoint, level: LevelDefinition) -> Bool {
        guard start.isOrthogonallyAligned(with: end), start != end else { return false }
        var cursor = start.step(toward: end)
        while cursor != end {
            if level.barriers.contains(cursor) || level.hazards.contains(cursor) {
                return false
            }
            cursor = cursor.step(toward: end)
        }
        return true
    }

    static func occupiedCells(state: GameState) -> Set<GridPoint> {
        Set(state.magnets.values).union(state.blocks.values)
    }

    static func canPlaceMagnet(
        _ magnetID: String,
        at cell: GridPoint,
        level: LevelDefinition,
        state: GameState
    ) -> Result<Void, MagnetRuleError> {
        guard let magnet = level.magnets.first(where: { $0.id == magnetID }) else {
            return .failure(.missingMagnet(magnetID))
        }
        guard magnet.movable else {
            return .failure(.fixedMagnet(magnetID))
        }
        guard isInside(cell, level: level) else {
            return .failure(.outsideBoard(cell))
        }
        guard !level.barriers.contains(cell), !level.hazards.contains(cell) else {
            return .failure(.blocked(cell))
        }

        let otherMagnets = state.magnets.filter { $0.key != magnetID }.map(\.value)
        if Set(otherMagnets).contains(cell) || Set(state.blocks.values).contains(cell) {
            return .failure(.occupied(cell))
        }
        return .success(())
    }

    @discardableResult
    static func relocateMagnet(
        _ magnetID: String,
        to cell: GridPoint,
        level: LevelDefinition,
        state: inout GameState
    ) -> Result<Void, MagnetRuleError> {
        let validation = canPlaceMagnet(magnetID, at: cell, level: level, state: state)
        guard case .success = validation else { return validation }
        if state.magnets[magnetID] != cell {
            state.recordUndoSnapshot()
            state.magnets[magnetID] = cell
            state.moves += 1
        }
        return .success(())
    }

    static func planPulse(
        magnetID: String,
        level: LevelDefinition,
        state: GameState,
        tuning: PhysicsTuning = .premiumSlice
    ) -> PulseResolution {
        guard let magnetPosition = state.magnets[magnetID],
              let magnetDefinition = level.magnets.first(where: { $0.id == magnetID })
        else {
            return PulseResolution(
                magnetID: magnetID,
                magnetPosition: .zero,
                moves: [],
                touchedHazard: false
            )
        }

        var occupied = occupiedCells(state: state)
        var moves: [BlockMove] = []
        var touchedHazard = false

        let matchingBlocks = level.blocks
            .filter { $0.polarity == magnetDefinition.polarity }
            .compactMap { block -> (definition: BlockDefinition, position: GridPoint)? in
                guard let position = state.blocks[block.id] else { return nil }
                return (block, position)
            }
            .filter { item in
                item.position.isOrthogonallyAligned(with: magnetPosition)
                    && item.position.manhattanDistance(to: magnetPosition) <= tuning.magneticRange
                    && hasLineOfSight(from: item.position, to: magnetPosition, level: level)
            }
            .sorted { lhs, rhs in
                lhs.position.manhattanDistance(to: magnetPosition) < rhs.position.manhattanDistance(to: magnetPosition)
            }

        for item in matchingBlocks {
            let destination = item.position.step(toward: magnetPosition)
            guard destination != magnetPosition else { continue }
            guard isInside(destination, level: level), !level.barriers.contains(destination) else { continue }
            if level.hazards.contains(destination) {
                touchedHazard = true
                continue
            }
            guard !occupied.contains(destination) else { continue }
            occupied.remove(item.position)
            occupied.insert(destination)
            moves.append(
                BlockMove(
                    blockID: item.definition.id,
                    from: item.position,
                    to: destination,
                    polarity: item.definition.polarity
                )
            )
        }

        return PulseResolution(
            magnetID: magnetID,
            magnetPosition: magnetPosition,
            moves: moves,
            touchedHazard: touchedHazard
        )
    }

    @discardableResult
    static func applyPulse(
        _ resolution: PulseResolution,
        level: LevelDefinition,
        state: inout GameState
    ) -> Bool {
        state.recordUndoSnapshot()
        state.pulses += 1
        for move in resolution.moves {
            state.blocks[move.blockID] = move.to
        }
        state.failed = resolution.touchedHazard
        state.solved = WinValidator.isSolved(level: level, state: state)
        return resolution.hasMotion
    }
}

enum WinValidator {
    static func isSolved(level: LevelDefinition, state: GameState) -> Bool {
        level.targets.allSatisfy { target in
            level.blocks.contains { block in
                block.polarity == target.polarity && state.blocks[block.id] == target.position
            }
        }
    }
}

enum SnapLogic {
    static func snap(
        worldPosition: CGPoint,
        boardOrigin: CGPoint,
        tileSize: CGFloat,
        level: LevelDefinition,
        tuning: PhysicsTuning = .premiumSlice
    ) -> SnapResult? {
        guard tileSize > 0 else { return nil }
        let x = Int(round((worldPosition.x - boardOrigin.x) / tileSize))
        let y = Int(round((worldPosition.y - boardOrigin.y) / tileSize))
        let cell = GridPoint(x: x, y: y)
        guard MagnetRuleEngine.isInside(cell, level: level) else { return nil }

        let snappedPoint = CGPoint(
            x: boardOrigin.x + CGFloat(cell.x) * tileSize,
            y: boardOrigin.y + CGFloat(cell.y) * tileSize
        )
        let distance = hypot(worldPosition.x - snappedPoint.x, worldPosition.y - snappedPoint.y) / tileSize
        return SnapResult(
            cell: cell,
            distance: distance,
            accepted: distance <= tuning.snapThreshold
        )
    }
}

enum MagnetForceResolver {
    static func forceVector(
        from block: GridPoint,
        toward magnet: GridPoint,
        polarityMatches: Bool,
        tuning: PhysicsTuning = .premiumSlice
    ) -> CGVector {
        guard polarityMatches, block.isOrthogonallyAligned(with: magnet), block != magnet else {
            return .zero
        }
        let distance = max(CGFloat(block.manhattanDistance(to: magnet)), 1)
        let magnitude = tuning.magneticForce / (distance * distance)
        let step = block.step(toward: magnet)
        return CGVector(
            dx: CGFloat(step.x - block.x) * magnitude,
            dy: CGFloat(step.y - block.y) * magnitude
        )
    }
}
