import CoreGraphics
import Foundation

enum ChargePolarity: String, CaseIterable, Codable, Equatable, Hashable, Identifiable {
    case cyan
    case amber
    case violet

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cyan: "Cyan"
        case .amber: "Amber"
        case .violet: "Violet"
        }
    }
}

enum Direction: String, CaseIterable, Codable, Equatable, Hashable {
    case north
    case east
    case south
    case west

    var offset: GridPoint {
        switch self {
        case .north: GridPoint(x: 0, y: 1)
        case .east: GridPoint(x: 1, y: 0)
        case .south: GridPoint(x: 0, y: -1)
        case .west: GridPoint(x: -1, y: 0)
        }
    }
}

struct GridPoint: Codable, Equatable, Hashable, CustomStringConvertible {
    var x: Int
    var y: Int

    var description: String { "(\(x), \(y))" }

    static let zero = GridPoint(x: 0, y: 0)

    func offsetBy(_ direction: Direction) -> GridPoint {
        let offset = direction.offset
        return GridPoint(x: x + offset.x, y: y + offset.y)
    }

    func manhattanDistance(to other: GridPoint) -> Int {
        abs(x - other.x) + abs(y - other.y)
    }

    func isOrthogonallyAligned(with other: GridPoint) -> Bool {
        x == other.x || y == other.y
    }

    func step(toward target: GridPoint) -> GridPoint {
        if x < target.x { return GridPoint(x: x + 1, y: y) }
        if x > target.x { return GridPoint(x: x - 1, y: y) }
        if y < target.y { return GridPoint(x: x, y: y + 1) }
        if y > target.y { return GridPoint(x: x, y: y - 1) }
        return self
    }
}

struct MagnetDefinition: Codable, Equatable, Hashable, Identifiable {
    var id: String
    var position: GridPoint
    var polarity: ChargePolarity
    var movable: Bool
}

struct BlockDefinition: Codable, Equatable, Hashable, Identifiable {
    var id: String
    var position: GridPoint
    var polarity: ChargePolarity
    var mass: Double
}

struct TargetDefinition: Codable, Equatable, Hashable, Identifiable {
    var id: String
    var position: GridPoint
    var polarity: ChargePolarity
}

struct FieldEmitterDefinition: Codable, Equatable, Hashable, Identifiable {
    var id: String
    var position: GridPoint
    var direction: Direction
    var polarity: ChargePolarity
}

struct LevelDefinition: Codable, Equatable, Hashable, Identifiable {
    var id: Int
    var title: String
    var labCode: String
    var columns: Int
    var rows: Int
    var parPulses: Int
    var magnets: [MagnetDefinition]
    var blocks: [BlockDefinition]
    var targets: [TargetDefinition]
    var barriers: Set<GridPoint>
    var emitters: [FieldEmitterDefinition]
    var hazards: Set<GridPoint>
    var hint: String

    var gridCells: [GridPoint] {
        (0..<columns).flatMap { x in
            (0..<rows).map { y in GridPoint(x: x, y: y) }
        }
    }
}

struct PhysicsTuning: Codable, Equatable {
    var blockMass: CGFloat
    var magnetMass: CGFloat
    var linearDamping: CGFloat
    var angularDamping: CGFloat
    var friction: CGFloat
    var restitution: CGFloat
    var magneticForce: CGFloat
    var magneticRange: Int
    var snapThreshold: CGFloat
    var tileContactSpring: CGFloat
    var slowMotionScale: CGFloat

    static let premiumSlice = PhysicsTuning(
        blockMass: 1.15,
        magnetMass: 3.8,
        linearDamping: 4.7,
        angularDamping: 7.0,
        friction: 0.36,
        restitution: 0.16,
        magneticForce: 930,
        magneticRange: 6,
        snapThreshold: 0.42,
        tileContactSpring: 0.24,
        slowMotionScale: 1.0
    )
}

struct CollisionCategory {
    static let board: UInt32 = 1 << 0
    static let block: UInt32 = 1 << 1
    static let magnet: UInt32 = 1 << 2
    static let barrier: UInt32 = 1 << 3
    static let hazard: UInt32 = 1 << 4
    static let target: UInt32 = 1 << 5
}

struct GameSnapshot: Codable, Equatable {
    var magnets: [String: GridPoint]
    var blocks: [String: GridPoint]
    var moves: Int
    var pulses: Int
    var solved: Bool
    var failed: Bool
}

struct GameState: Codable, Equatable {
    var levelID: Int
    var magnets: [String: GridPoint]
    var blocks: [String: GridPoint]
    var moves: Int
    var pulses: Int
    var solved: Bool
    var failed: Bool
    var retries: Int
    var undoStack: [GameSnapshot]

    init(level: LevelDefinition) {
        levelID = level.id
        magnets = Dictionary(uniqueKeysWithValues: level.magnets.map { ($0.id, $0.position) })
        blocks = Dictionary(uniqueKeysWithValues: level.blocks.map { ($0.id, $0.position) })
        moves = 0
        pulses = 0
        solved = false
        failed = false
        retries = 0
        undoStack = []
    }

    var snapshot: GameSnapshot {
        GameSnapshot(
            magnets: magnets,
            blocks: blocks,
            moves: moves,
            pulses: pulses,
            solved: solved,
            failed: failed
        )
    }

    var canUndo: Bool {
        !undoStack.isEmpty
    }

    mutating func recordUndoSnapshot() {
        undoStack.append(snapshot)
        if undoStack.count > 16 {
            undoStack.removeFirst()
        }
    }

    mutating func restoreUndoSnapshot() -> Bool {
        guard let last = undoStack.popLast() else { return false }
        magnets = last.magnets
        blocks = last.blocks
        moves = last.moves
        pulses = last.pulses
        solved = last.solved
        failed = last.failed
        return true
    }

    mutating func markRetry(level: LevelDefinition) {
        retries += 1
        let previousRetries = retries
        self = GameState(level: level)
        retries = previousRetries
    }
}

struct BlockMove: Codable, Equatable, Hashable, Identifiable {
    var id: String { blockID }
    var blockID: String
    var from: GridPoint
    var to: GridPoint
    var polarity: ChargePolarity
}

struct PulseResolution: Codable, Equatable {
    var magnetID: String
    var magnetPosition: GridPoint
    var moves: [BlockMove]
    var touchedHazard: Bool

    var hasMotion: Bool {
        !moves.isEmpty
    }
}

struct SnapResult: Equatable {
    var cell: GridPoint
    var distance: CGFloat
    var accepted: Bool
}
