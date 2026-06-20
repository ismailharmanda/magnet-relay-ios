import Foundation

enum LevelArchetype: String, Codable, CaseIterable, Equatable {
    case straightPulse
    case singleReposition
    case twoLaneSwitch
    case barrierSetup
    case polaritySwitch
    case hazardDetour
    case threePolarityTight
}

struct LevelQualityMetrics: Codable, Equatable {
    var requiredMoveCount: Int
    var activeMagnetCount: Int
    var distinctDestinationCount: Int
    var polarityCount: Int
    var hasZeroMoveShortcut: Bool
}

struct GeneratedLevelCandidate: Codable, Equatable {
    var ordinal: Int
    var seed: UInt64
    var band: LevelDifficultyBand
    var mechanicTier: MechanicTier
    var archetype: LevelArchetype
    var qualityMetrics: LevelQualityMetrics
    var level: LevelDefinition
    var solveReport: SolveReport
}

struct LevelDifficultyPolicy: Equatable {
    var archetype: LevelArchetype
    var mechanicTier: MechanicTier
    var minimumMoveCount: Int
    var minimumActiveMagnetCount: Int
    var requiredPolarityCount: Int
    var requiresBarriers: Bool
    var requiresHazards: Bool
    var columns: Int
    var rows: Int
    var laneCount: Int
    var targetPulseCount: Int
    var maxPulseCount: Int
    var parPadding: Int

    static func campaignV2(ordinal: Int) -> LevelDifficultyPolicy {
        switch ordinal {
        case 1...10:
            return LevelDifficultyPolicy(
                archetype: .straightPulse,
                mechanicTier: .singlePolarityOpenLanes,
                minimumMoveCount: 0,
                minimumActiveMagnetCount: 0,
                requiredPolarityCount: 1,
                requiresBarriers: false,
                requiresHazards: false,
                columns: 6,
                rows: 7,
                laneCount: 1,
                targetPulseCount: 2,
                maxPulseCount: 4,
                parPadding: 2
            )
        case 11...40:
            return LevelDifficultyPolicy(
                archetype: .singleReposition,
                mechanicTier: .singlePolarityOpenLanes,
                minimumMoveCount: 1,
                minimumActiveMagnetCount: 1,
                requiredPolarityCount: 1,
                requiresBarriers: false,
                requiresHazards: false,
                columns: 6,
                rows: 7,
                laneCount: 1,
                targetPulseCount: ordinal.isMultiple(of: 3) ? 3 : 2,
                maxPulseCount: 4,
                parPadding: 2
            )
        case 41...80:
            return LevelDifficultyPolicy(
                archetype: ordinal.isMultiple(of: 2) ? .barrierSetup : .twoLaneSwitch,
                mechanicTier: .barriers,
                minimumMoveCount: 2,
                minimumActiveMagnetCount: 1,
                requiredPolarityCount: 1,
                requiresBarriers: true,
                requiresHazards: false,
                columns: 7,
                rows: 7,
                laneCount: 2,
                targetPulseCount: ordinal.isMultiple(of: 3) ? 4 : 3,
                maxPulseCount: 5,
                parPadding: 1
            )
        case 81...120:
            return LevelDifficultyPolicy(
                archetype: .polaritySwitch,
                mechanicTier: .multiPolarity,
                minimumMoveCount: 2,
                minimumActiveMagnetCount: 2,
                requiredPolarityCount: 2,
                requiresBarriers: false,
                requiresHazards: false,
                columns: 7,
                rows: 7,
                laneCount: 3,
                targetPulseCount: ordinal.isMultiple(of: 4) ? 6 : 5,
                maxPulseCount: 7,
                parPadding: 1
            )
        case 121...160:
            return LevelDifficultyPolicy(
                archetype: .hazardDetour,
                mechanicTier: .hazards,
                minimumMoveCount: 3,
                minimumActiveMagnetCount: 2,
                requiredPolarityCount: 2,
                requiresBarriers: false,
                requiresHazards: true,
                columns: 8,
                rows: 8,
                laneCount: 3,
                targetPulseCount: ordinal.isMultiple(of: 4) ? 7 : 6,
                maxPulseCount: 9,
                parPadding: 1
            )
        default:
            return LevelDifficultyPolicy(
                archetype: .threePolarityTight,
                mechanicTier: .tightMoveBudgets,
                minimumMoveCount: 4,
                minimumActiveMagnetCount: 3,
                requiredPolarityCount: 3,
                requiresBarriers: true,
                requiresHazards: true,
                columns: 8,
                rows: 9,
                laneCount: 4,
                targetPulseCount: ordinal.isMultiple(of: 5) ? 9 : 8,
                maxPulseCount: 11,
                parPadding: 0
            )
        }
    }

    static func defaultPolicy(band: LevelDifficultyBand, mechanicTier: MechanicTier) -> LevelDifficultyPolicy {
        switch band {
        case .tutorial:
            return LevelDifficultyPolicy(
                archetype: .straightPulse,
                mechanicTier: mechanicTier,
                minimumMoveCount: 0,
                minimumActiveMagnetCount: 0,
                requiredPolarityCount: 1,
                requiresBarriers: false,
                requiresHazards: false,
                columns: 6,
                rows: 7,
                laneCount: 1,
                targetPulseCount: 2,
                maxPulseCount: 4,
                parPadding: 2
            )
        case .easy:
            return LevelDifficultyPolicy(
                archetype: .singleReposition,
                mechanicTier: mechanicTier,
                minimumMoveCount: 1,
                minimumActiveMagnetCount: 1,
                requiredPolarityCount: 1,
                requiresBarriers: mechanicTier == .barriers,
                requiresHazards: false,
                columns: 7,
                rows: 7,
                laneCount: 1,
                targetPulseCount: 3,
                maxPulseCount: 5,
                parPadding: 2
            )
        case .medium:
            return LevelDifficultyPolicy(
                archetype: .polaritySwitch,
                mechanicTier: mechanicTier,
                minimumMoveCount: 2,
                minimumActiveMagnetCount: 2,
                requiredPolarityCount: 2,
                requiresBarriers: false,
                requiresHazards: false,
                columns: 7,
                rows: 7,
                laneCount: 2,
                targetPulseCount: 5,
                maxPulseCount: 7,
                parPadding: 1
            )
        case .hard:
            return LevelDifficultyPolicy(
                archetype: .hazardDetour,
                mechanicTier: mechanicTier,
                minimumMoveCount: 3,
                minimumActiveMagnetCount: 2,
                requiredPolarityCount: 2,
                requiresBarriers: false,
                requiresHazards: true,
                columns: 8,
                rows: 8,
                laneCount: 3,
                targetPulseCount: 6,
                maxPulseCount: 9,
                parPadding: 1
            )
        case .expert:
            return LevelDifficultyPolicy(
                archetype: .threePolarityTight,
                mechanicTier: mechanicTier,
                minimumMoveCount: 4,
                minimumActiveMagnetCount: 3,
                requiredPolarityCount: 3,
                requiresBarriers: true,
                requiresHazards: true,
                columns: 8,
                rows: 9,
                laneCount: 4,
                targetPulseCount: 8,
                maxPulseCount: 11,
                parPadding: 0
            )
        }
    }
}

enum LevelGenerator {
    static func generate(
        count: Int,
        seed: UInt64,
        tierProfile: String = "default"
    ) -> [GeneratedLevelCandidate] {
        guard count > 0 else { return [] }
        var rng = SeededRandom(seed: seed)
        var candidates: [GeneratedLevelCandidate] = []

        for index in 0..<count {
            let ordinal = index + 1
            if ProcessInfo.processInfo.environment["MR_LEVELGEN_PROGRESS"] == "1" {
                fputs("levelgen ordinal=\(ordinal)\n", stderr)
            }
            let band = difficultyBand(for: index, totalCount: count)
            let fallbackTier = mechanicTier(for: band, tierProfile: tierProfile)
            let policy = policy(for: ordinal, band: band, mechanicTier: fallbackTier, tierProfile: tierProfile)
            var accepted: GeneratedLevelCandidate?

            for attempt in 0..<160 {
                let levelSeed = rng.next() ^ UInt64(ordinal) &* 0x9E37_79B9_7F4A_7C15 ^ UInt64(attempt)
                guard let draft = makePuzzleDraft(
                    ordinal: ordinal,
                    seed: levelSeed,
                    band: band,
                    policy: policy,
                    tierProfile: tierProfile
                ) else { continue }

                if let candidate = validateGeneratedCandidate(
                    level: draft.level,
                    band: band,
                    mechanicTier: policy.mechanicTier,
                    seed: levelSeed,
                    ordinal: ordinal,
                    archetype: policy.archetype,
                    policy: policy,
                    scriptedSolution: draft.scriptedSolution
                ) {
                    accepted = candidate
                    break
                }
            }

            if let accepted {
                candidates.append(accepted)
            }
        }

        return candidates
    }

    static func validateGeneratedCandidate(
        level: LevelDefinition,
        band: LevelDifficultyBand,
        mechanicTier: MechanicTier,
        seed: UInt64,
        ordinal: Int = 0,
        archetype: LevelArchetype = .singleReposition,
        policy: LevelDifficultyPolicy? = nil,
        scriptedSolution: [PlannedMove]? = nil
    ) -> GeneratedLevelCandidate? {
        guard isStructurallyValid(level: level) else { return nil }
        let initialState = GameState(level: level)
        guard !WinValidator.isSolved(level: level, state: initialState) else { return nil }

        if let scriptedSolution {
            let intendedReport = LevelSolver.replay(level: level, plannedMoves: scriptedSolution)
            guard intendedReport.solvable,
                  !intendedReport.shortestSolution.contains(where: \.touchedHazard)
            else { return nil }
        }

        let effectivePolicy = policy ?? LevelDifficultyPolicy.defaultPolicy(
            band: band,
            mechanicTier: mechanicTier
        )
        let report = LevelSolver.solve(
            level: level,
            configuration: LevelSolver.Configuration(
                maxSolutionActions: max(level.parPulses + 8, effectivePolicy.maxPulseCount + 6, band.minimumSolutionPulses + 6),
                maxVisitedStates: 180_000,
                requiresProgressImprovement: true
            )
        )

        let metrics = qualityMetrics(level: level, report: report)
        guard report.solvable,
              report.pulseCount >= band.minimumSolutionPulses,
              report.pulseCount <= effectivePolicy.maxPulseCount,
              report.moveCount >= effectivePolicy.minimumMoveCount,
              metrics.activeMagnetCount >= effectivePolicy.minimumActiveMagnetCount,
              metrics.polarityCount >= effectivePolicy.requiredPolarityCount,
              !report.shortestSolution.contains(where: \.touchedHazard),
              !effectivePolicy.requiresBarriers || !level.barriers.isEmpty,
              !effectivePolicy.requiresHazards || !level.hazards.isEmpty,
              !metrics.hasZeroMoveShortcut || effectivePolicy.minimumMoveCount == 0
        else { return nil }

        return GeneratedLevelCandidate(
            ordinal: ordinal,
            seed: seed,
            band: band,
            mechanicTier: mechanicTier,
            archetype: archetype,
            qualityMetrics: metrics,
            level: level,
            solveReport: report
        )
    }

    private static func makePuzzleDraft(
        ordinal: Int,
        seed: UInt64,
        band: LevelDifficultyBand,
        policy: LevelDifficultyPolicy,
        tierProfile: String
    ) -> CandidateDraft? {
        var rng = SeededRandom(seed: seed)
        let laneRows = chooseLaneRows(count: policy.laneCount, rows: policy.rows, rng: &rng)
        let steps = pulseSteps(total: policy.targetPulseCount, laneCount: policy.laneCount, columns: policy.columns, policy: policy)
        let laneSlots = magnetSlots(for: policy.archetype, laneCount: policy.laneCount)

        var lanes: [LanePlan] = []
        var reserved = Set<GridPoint>()

        for laneIndex in 0..<policy.laneCount {
            let slot = laneSlots[laneIndex]
            let polarity = polarity(forSlot: slot)
            let geometry = makeLaneGeometry(
                laneIndex: laneIndex,
                row: laneRows[laneIndex],
                steps: steps[laneIndex],
                columns: policy.columns,
                needsWrongSideBlocker: policy.requiresBarriers || policy.requiresHazards,
                rng: &rng
            )
            let magnetID = "gm-\(polarity.rawValue)-\(slot)"
            let lane = LanePlan(
                magnetID: magnetID,
                slot: slot,
                polarity: polarity,
                blockID: "gb-\(polarity.rawValue)-\(laneIndex)",
                targetID: "gt-\(polarity.rawValue)-\(laneIndex)",
                blockCell: geometry.block,
                targetCell: geometry.target,
                destinationCell: geometry.magnetDestination,
                wrongSideBlocker: geometry.wrongSideBlocker,
                steps: geometry.steps
            )
            lanes.append(lane)
            reserved.insert(lane.blockCell)
            reserved.insert(lane.targetCell)
            reserved.insert(lane.destinationCell)
            if let wrongSideBlocker = lane.wrongSideBlocker {
                reserved.insert(wrongSideBlocker)
            }
        }

        var magnetStarts: [String: GridPoint] = [:]
        let sortedSlots = Array(Set(lanes.map(\.slot))).sorted()
        for slot in sortedSlots {
            let magnetID = "gm-\(polarity(forSlot: slot).rawValue)-\(slot)"
            guard let parkingCell = policy.archetype == .straightPulse
                ? lanes.first(where: { $0.slot == slot })?.destinationCell
                : findParkingCell(
                    slot: slot,
                    polarity: polarity(forSlot: slot),
                    reserved: reserved.union(Set(magnetStarts.values)),
                    lanes: lanes,
                    columns: policy.columns,
                    rows: policy.rows,
                    rng: &rng
                )
            else { return nil }
            magnetStarts[magnetID] = parkingCell
            reserved.insert(parkingCell)
        }

        let barriers = makeBarriers(policy: policy, lanes: lanes, columns: policy.columns, rows: policy.rows, reserved: reserved, rng: &rng)
        var hazards = makeHazards(policy: policy, lanes: lanes, columns: policy.columns, rows: policy.rows, reserved: reserved.union(barriers), rng: &rng)
        hazards.subtract(barriers)

        let magnets = sortedSlots.map { slot in
            let polarity = polarity(forSlot: slot)
            let magnetID = "gm-\(polarity.rawValue)-\(slot)"
            return MagnetDefinition(
                id: magnetID,
                position: magnetStarts[magnetID]!,
                polarity: polarity,
                movable: true
            )
        }
        let blocks = lanes.map { lane in
            BlockDefinition(
                id: lane.blockID,
                position: lane.blockCell,
                polarity: lane.polarity,
                mass: band == .expert ? 1.18 : 1.0
            )
        }
        let targets = lanes.map { lane in
            TargetDefinition(
                id: lane.targetID,
                position: lane.targetCell,
                polarity: lane.polarity
            )
        }
        let scriptedSolution = scriptedSolution(for: lanes, magnetStarts: magnetStarts)
        let totalPulses = lanes.map(\.steps).reduce(0, +)

        return CandidateDraft(
            level: LevelDefinition(
                id: levelID(for: ordinal, tierProfile: tierProfile),
                title: title(for: ordinal, tierProfile: tierProfile),
                labCode: "MG-\(String(format: "%04d", ordinal))",
                columns: policy.columns,
                rows: policy.rows,
                parPulses: totalPulses + policy.parPadding,
                magnets: magnets,
                blocks: blocks,
                targets: targets,
                barriers: barriers,
                emitters: [],
                hazards: hazards,
                hint: hint(for: policy.archetype, band: band, tier: policy.mechanicTier, tierProfile: tierProfile)
            ),
            scriptedSolution: scriptedSolution
        )
    }

    private static func isStructurallyValid(level: LevelDefinition) -> Bool {
        guard level.columns > 1, level.rows > 1 else { return false }

        var occupied = Set<GridPoint>()
        for magnet in level.magnets {
            guard MagnetRuleEngine.isInside(magnet.position, level: level),
                  occupied.insert(magnet.position).inserted
            else { return false }
        }
        for block in level.blocks {
            guard MagnetRuleEngine.isInside(block.position, level: level),
                  occupied.insert(block.position).inserted
            else { return false }
        }
        for target in level.targets {
            guard MagnetRuleEngine.isInside(target.position, level: level),
                  !level.barriers.contains(target.position),
                  !level.hazards.contains(target.position),
                  level.blocks.contains(where: { $0.polarity == target.polarity })
            else { return false }
        }
        for barrier in level.barriers {
            guard MagnetRuleEngine.isInside(barrier, level: level),
                  !occupied.contains(barrier)
            else { return false }
        }
        for hazard in level.hazards {
            guard MagnetRuleEngine.isInside(hazard, level: level),
                  !occupied.contains(hazard),
                  !level.barriers.contains(hazard)
            else { return false }
        }
        return true
    }

    private static func policy(
        for ordinal: Int,
        band: LevelDifficultyBand,
        mechanicTier: MechanicTier,
        tierProfile: String
    ) -> LevelDifficultyPolicy {
        if tierProfile == "campaign-v2" {
            return LevelDifficultyPolicy.campaignV2(ordinal: ordinal)
        }
        return LevelDifficultyPolicy.defaultPolicy(band: band, mechanicTier: mechanicTier)
    }

    private static func difficultyBand(for index: Int, totalCount: Int) -> LevelDifficultyBand {
        let bucket = min(LevelDifficultyBand.allCases.count - 1, index * LevelDifficultyBand.allCases.count / max(totalCount, 1))
        return LevelDifficultyBand.allCases[bucket]
    }

    private static func mechanicTier(for band: LevelDifficultyBand, tierProfile: String) -> MechanicTier {
        guard tierProfile == "default" || tierProfile == "campaign-v2" else { return .singlePolarityOpenLanes }
        switch band {
        case .tutorial:
            return .singlePolarityOpenLanes
        case .easy:
            return .barriers
        case .medium:
            return .multiPolarity
        case .hard:
            return .hazards
        case .expert:
            return .tightMoveBudgets
        }
    }

    private static func levelID(for ordinal: Int, tierProfile: String) -> Int {
        tierProfile == "campaign-v2" ? 12 + ordinal : 10_000 + ordinal
    }

    private static func title(for ordinal: Int, tierProfile: String) -> String {
        if tierProfile == "campaign-v2" {
            return "Calibration \(String(format: "%03d", ordinal))"
        }
        return "Generated Calibration \(ordinal)"
    }

    private static func hint(
        for archetype: LevelArchetype,
        band: LevelDifficultyBand,
        tier: MechanicTier,
        tierProfile: String
    ) -> String {
        guard tierProfile == "campaign-v2" else {
            return "Generated test puzzle. Validate with MagnetRelayLevelPlanner before catalog use."
        }

        switch archetype {
        case .straightPulse:
            return "Keep the lane open and pulse the matching charge into its socket."
        case .singleReposition:
            return "Move the magnet onto the active sightline before pulsing the charge home."
        case .twoLaneSwitch:
            return "Reuse the same magnet on both lanes; each lane needs its own setup."
        case .barrierSetup:
            return "Barriers close the wrong approach, so pick the clear side before each pulse."
        case .polaritySwitch:
            return "Solve each polarity with its matching magnet before switching colors."
        case .hazardDetour:
            return "Avoid discharge cells by setting up the safe lane before every pulse."
        case .threePolarityTight:
            return "Line up all three polarities cleanly; there is no spare pulse budget."
        }
    }

    private static func chooseLaneRows(count: Int, rows: Int, rng: inout SeededRandom) -> [Int] {
        switch count {
        case 1:
            return [min(rows - 2, max(1, rows / 2 + rng.int(in: -1...1)))]
        case 2:
            return [2, rows - 3].map { min(rows - 2, max(1, $0)) }
        case 3:
            return [1, rows / 2, rows - 2].map { min(rows - 2, max(1, $0)) }
        default:
            let stride = max(1, (rows - 2) / max(1, count))
            var result: [Int] = []
            var row = 1
            while result.count < count, row < rows - 1 {
                result.append(row)
                row += stride
            }
            row = rows - 2
            while result.count < count {
                if !result.contains(row) {
                    result.append(row)
                }
                row = max(1, row - 1)
            }
            return result.sorted()
        }
    }

    private static func pulseSteps(
        total: Int,
        laneCount: Int,
        columns: Int,
        policy: LevelDifficultyPolicy
    ) -> [Int] {
        let maxStep = max(1, columns - (policy.requiresBarriers || policy.requiresHazards ? 4 : 3))
        var steps = Array(repeating: max(1, total / laneCount), count: laneCount)
        var remainder = max(0, total - steps.reduce(0, +))
        var index = 0
        while remainder > 0 {
            steps[index % laneCount] += 1
            remainder -= 1
            index += 1
        }
        return steps.map { min(maxStep, max(1, $0)) }
    }

    private static func magnetSlots(for archetype: LevelArchetype, laneCount: Int) -> [Int] {
        let slots: [Int]
        switch archetype {
        case .straightPulse, .singleReposition:
            slots = [0]
        case .twoLaneSwitch, .barrierSetup:
            slots = [0, 0]
        case .polaritySwitch:
            slots = [0, 1]
        case .hazardDetour:
            slots = [0, 1, 0]
        case .threePolarityTight:
            slots = [0, 1, 2, 0]
        }

        if slots.count >= laneCount {
            return Array(slots.prefix(laneCount))
        }
        return (0..<laneCount).map { slots[$0 % slots.count] }
    }

    private static func polarity(forSlot slot: Int) -> ChargePolarity {
        ChargePolarity.allCases[slot % ChargePolarity.allCases.count]
    }

    private static func makeLaneGeometry(
        laneIndex: Int,
        row: Int,
        steps: Int,
        columns: Int,
        needsWrongSideBlocker: Bool,
        rng: inout SeededRandom
    ) -> LaneGeometry {
        let pullsRight = (laneIndex + (rng.nextBool() ? 0 : 1)).isMultiple(of: 2)
        let buffer = needsWrongSideBlocker ? 2 : 1
        let actualSteps = min(max(1, steps), max(1, columns - buffer - 3))

        if pullsRight {
            let blockX = buffer
            return LaneGeometry(
                block: GridPoint(x: blockX, y: row),
                target: GridPoint(x: blockX + actualSteps, y: row),
                magnetDestination: GridPoint(x: columns - 1, y: row),
                wrongSideBlocker: needsWrongSideBlocker ? GridPoint(x: blockX - 1, y: row) : nil,
                steps: actualSteps
            )
        }

        let blockX = columns - 1 - buffer
        return LaneGeometry(
            block: GridPoint(x: blockX, y: row),
            target: GridPoint(x: blockX - actualSteps, y: row),
            magnetDestination: GridPoint(x: 0, y: row),
            wrongSideBlocker: needsWrongSideBlocker ? GridPoint(x: blockX + 1, y: row) : nil,
            steps: actualSteps
        )
    }

    private static func findParkingCell(
        slot: Int,
        polarity: ChargePolarity,
        reserved: Set<GridPoint>,
        lanes: [LanePlan],
        columns: Int,
        rows: Int,
        rng: inout SeededRandom
    ) -> GridPoint? {
        var candidates: [GridPoint] = []
        let matchingBlocks = lanes
            .filter { $0.polarity == polarity }
            .map(\.blockCell)

        for y in 1..<(rows - 1) {
            for x in 1..<(columns - 1) {
                let cell = GridPoint(x: x, y: y)
                guard !reserved.contains(cell),
                      matchingBlocks.allSatisfy({ !$0.isOrthogonallyAligned(with: cell) })
                else { continue }
                candidates.append(cell)
            }
        }

        guard !candidates.isEmpty else { return nil }
        let index = rng.int(in: 0...(candidates.count - 1))
        return candidates[index]
    }

    private static func makeBarriers(
        policy: LevelDifficultyPolicy,
        lanes: [LanePlan],
        columns: Int,
        rows: Int,
        reserved: Set<GridPoint>,
        rng: inout SeededRandom
    ) -> Set<GridPoint> {
        guard policy.requiresBarriers else { return [] }
        var barriers = Set<GridPoint>()
        if !policy.requiresHazards {
            for lane in lanes {
                if let blocker = lane.wrongSideBlocker {
                    barriers.insert(blocker)
                }
            }
        }

        let desiredCount = max(policy.laneCount, policy.mechanicTier == .tightMoveBudgets ? 5 : 3)
        return fillDecorativeCells(
            targetCount: desiredCount,
            existing: barriers,
            columns: columns,
            rows: rows,
            laneRows: Set(lanes.map(\.blockCell.y)),
            reserved: reserved,
            rng: &rng
        )
    }

    private static func makeHazards(
        policy: LevelDifficultyPolicy,
        lanes: [LanePlan],
        columns: Int,
        rows: Int,
        reserved: Set<GridPoint>,
        rng: inout SeededRandom
    ) -> Set<GridPoint> {
        guard policy.requiresHazards else { return [] }
        var hazards = Set<GridPoint>()
        for lane in lanes {
            if let blocker = lane.wrongSideBlocker {
                hazards.insert(blocker)
            }
        }

        let desiredCount = max(policy.laneCount, policy.mechanicTier == .tightMoveBudgets ? 5 : 3)
        return fillDecorativeCells(
            targetCount: desiredCount,
            existing: hazards,
            columns: columns,
            rows: rows,
            laneRows: Set(lanes.map(\.blockCell.y)),
            reserved: reserved,
            rng: &rng
        )
    }

    private static func fillDecorativeCells(
        targetCount: Int,
        existing: Set<GridPoint>,
        columns: Int,
        rows: Int,
        laneRows: Set<Int>,
        reserved: Set<GridPoint>,
        rng: inout SeededRandom
    ) -> Set<GridPoint> {
        var result = existing
        var candidates: [GridPoint] = []
        for x in 1..<(columns - 1) {
            for y in 1..<(rows - 1) {
                let cell = GridPoint(x: x, y: y)
                guard !laneRows.contains(cell.y),
                      !reserved.contains(cell),
                      !result.contains(cell)
                else { continue }
                candidates.append(cell)
            }
        }

        while result.count < targetCount, !candidates.isEmpty {
            let index = rng.int(in: 0...(candidates.count - 1))
            result.insert(candidates.remove(at: index))
        }
        return result
    }

    private static func scriptedSolution(for lanes: [LanePlan], magnetStarts: [String: GridPoint]) -> [PlannedMove] {
        var magnetCells = magnetStarts
        var solution: [PlannedMove] = []
        for lane in lanes {
            for _ in 0..<lane.steps {
                let origin = magnetCells[lane.magnetID] ?? lane.destinationCell
                solution.append(PlannedMove(
                    magnetID: lane.magnetID,
                    originCell: origin,
                    destinationCell: lane.destinationCell,
                    pulseMoves: [],
                    touchedHazard: false
                ))
                magnetCells[lane.magnetID] = lane.destinationCell
            }
        }
        return solution
    }

    private static func qualityMetrics(level: LevelDefinition, report: SolveReport) -> LevelQualityMetrics {
        let repositionMoves = report.shortestSolution.filter { $0.originCell != $0.destinationCell }
        return LevelQualityMetrics(
            requiredMoveCount: report.moveCount,
            activeMagnetCount: Set(repositionMoves.map(\.magnetID)).count,
            distinctDestinationCount: Set(repositionMoves.map(\.destinationCell)).count,
            polarityCount: Set(level.blocks.map(\.polarity)).count,
            hasZeroMoveShortcut: report.solvable && report.moveCount == 0
        )
    }
}

private struct CandidateDraft {
    var level: LevelDefinition
    var scriptedSolution: [PlannedMove]
}

private struct LanePlan {
    var magnetID: String
    var slot: Int
    var polarity: ChargePolarity
    var blockID: String
    var targetID: String
    var blockCell: GridPoint
    var targetCell: GridPoint
    var destinationCell: GridPoint
    var wrongSideBlocker: GridPoint?
    var steps: Int
}

private struct LaneGeometry {
    var block: GridPoint
    var target: GridPoint
    var magnetDestination: GridPoint
    var wrongSideBlocker: GridPoint?
    var steps: Int
}

struct SeededRandom: Equatable {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0xD1B5_4A32_D192_ED03 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
        value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
        return value ^ (value >> 31)
    }

    mutating func nextBool() -> Bool {
        next() & 1 == 0
    }

    mutating func int(in range: ClosedRange<Int>) -> Int {
        let lower = range.lowerBound
        let upper = range.upperBound
        guard upper >= lower else { return lower }
        let span = UInt64(upper - lower + 1)
        return lower + Int(next() % span)
    }
}
