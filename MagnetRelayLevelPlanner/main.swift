import Foundation

private enum PlannerCLI {
    static func run() throws {
        var arguments = Array(CommandLine.arguments.dropFirst())
        guard let command = arguments.first else {
            printUsage()
            throw ExitCode.failure
        }
        arguments.removeFirst()

        switch command {
        case "validate-catalog":
            try validateCatalog()
        case "generate":
            try generate(arguments: arguments)
        case "materialize-campaign":
            try materializeCampaign(arguments: arguments)
        case "explain":
            try explain(arguments: arguments)
        case "-h", "--help", "help":
            printUsage()
        default:
            print("Unknown command: \(command)")
            printUsage()
            throw ExitCode.failure
        }
    }

    private static func validateCatalog() throws {
        var reports: [SolveReport] = []
        for level in LevelCatalog.levels {
            let report = LevelSolver.solve(level: level, configuration: solveConfiguration(for: level))
            reports.append(report)
            let status = report.solvable ? "OK" : "FAIL"
            print("\(status) \(level.labCode) pulses=\(report.pulseCount) moves=\(report.moveCount) score=\(report.difficultyScore) visited=\(report.visitedStateCount)")
            fflush(stdout)
        }

        let failed = reports.filter { !$0.solvable }

        print("VALID \(reports.count - failed.count)/\(reports.count)")
        if !failed.isEmpty {
            throw ExitCode.failure
        }
    }

    private static func generate(arguments: [String]) throws {
        let count = intValue(arguments, flag: "--count") ?? 100
        let seed = uintValue(arguments, flag: "--seed") ?? 1
        let tierProfile = stringValue(arguments, flag: "--tier-profile") ?? "default"
        let candidates = LevelGenerator.generate(count: count, seed: seed, tierProfile: tierProfile)

        let export = GeneratedBatchExport(
            seed: seed,
            requestedCount: count,
            emittedCount: candidates.count,
            tierProfile: tierProfile,
            candidates: candidates.map(GeneratedLevelExport.init(candidate:))
        )

        let outputDirectory = URL(fileURLWithPath: "build/generated-levels", isDirectory: true)
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        let outputURL = outputDirectory.appendingPathComponent("generated-\(seed)-\(count).json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(export).write(to: outputURL, options: .atomic)

        print("GENERATED \(candidates.count)/\(count)")
        print(outputURL.path)
        if candidates.count != count {
            throw ExitCode.failure
        }
    }

    private static func materializeCampaign(arguments: [String]) throws {
        let count = intValue(arguments, flag: "--count") ?? 200
        let seed = uintValue(arguments, flag: "--seed") ?? 42
        let tierProfile = stringValue(arguments, flag: "--tier-profile") ?? "campaign-v2"
        let candidates = LevelGenerator.generate(count: count, seed: seed, tierProfile: tierProfile)
        guard candidates.count == count else {
            print("MATERIALIZED \(candidates.count)/\(count)")
            throw ExitCode.failure
        }

        let outputURL = URL(fileURLWithPath: "MagnetRelay/Data/GeneratedLevelCatalog.swift")
        let source = SwiftCatalogMaterializer.source(
            levels: candidates.map(\.level),
            count: count,
            seed: seed,
            tierProfile: tierProfile
        )
        try source.write(to: outputURL, atomically: true, encoding: .utf8)

        print("MATERIALIZED \(candidates.count)/\(count)")
        print(outputURL.path)
    }

    private static func explain(arguments: [String]) throws {
        guard let levelID = intValue(arguments, flag: "--level-id") ?? arguments.first.flatMap(Int.init) else {
            print("Missing --level-id <id>")
            throw ExitCode.failure
        }
        let level = LevelCatalog.level(id: levelID)
        let report = LevelSolver.solve(level: level, configuration: solveConfiguration(for: level))

        print("\(level.labCode) \(level.title)")
        print("solvable=\(report.solvable) pulses=\(report.pulseCount) moves=\(report.moveCount) score=\(report.difficultyScore) visited=\(report.visitedStateCount)")
        if let reason = report.failureReason {
            print("failure=\(reason)")
        }
        for (index, move) in report.shortestSolution.enumerated() {
            print("\(index + 1). \(move)")
        }
    }

    private static func printUsage() {
        print("""
        MagnetRelayLevelPlanner

        Commands:
          validate-catalog
          generate --count 1000 --seed <int> --tier-profile default
          materialize-campaign --count 200 --seed <int> --tier-profile campaign-v2
          explain --level-id <id>
        """)
    }

    private static func solveConfiguration(for level: LevelDefinition) -> LevelSolver.Configuration {
        level.labCode.hasPrefix("MG-") ? .generatedCatalog(level: level) : .catalog(level: level)
    }

    private static func stringValue(_ arguments: [String], flag: String) -> String? {
        guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else { return nil }
        return arguments[index + 1]
    }

    private static func intValue(_ arguments: [String], flag: String) -> Int? {
        stringValue(arguments, flag: flag).flatMap(Int.init)
    }

    private static func uintValue(_ arguments: [String], flag: String) -> UInt64? {
        stringValue(arguments, flag: flag).flatMap(UInt64.init)
    }
}

private enum ExitCode: Error {
    case failure
}

private struct GeneratedBatchExport: Codable {
    var seed: UInt64
    var requestedCount: Int
    var emittedCount: Int
    var tierProfile: String
    var candidates: [GeneratedLevelExport]
}

private struct GeneratedLevelExport: Codable {
    var ordinal: Int
    var seed: UInt64
    var band: LevelDifficultyBand
    var mechanicTier: MechanicTier
    var archetype: LevelArchetype
    var qualityMetrics: LevelQualityMetrics
    var level: LevelExport
    var solveReport: SolveReport

    init(candidate: GeneratedLevelCandidate) {
        ordinal = candidate.ordinal
        seed = candidate.seed
        band = candidate.band
        mechanicTier = candidate.mechanicTier
        archetype = candidate.archetype
        qualityMetrics = candidate.qualityMetrics
        level = LevelExport(level: candidate.level)
        solveReport = candidate.solveReport
    }
}

private struct LevelExport: Codable {
    var id: Int
    var title: String
    var labCode: String
    var columns: Int
    var rows: Int
    var parPulses: Int
    var magnets: [MagnetDefinition]
    var blocks: [BlockDefinition]
    var targets: [TargetDefinition]
    var barriers: [GridPoint]
    var emitters: [FieldEmitterDefinition]
    var hazards: [GridPoint]
    var hint: String

    init(level: LevelDefinition) {
        id = level.id
        title = level.title
        labCode = level.labCode
        columns = level.columns
        rows = level.rows
        parPulses = level.parPulses
        magnets = level.magnets
        blocks = level.blocks
        targets = level.targets
        barriers = level.barriers.sortedGridPoints()
        emitters = level.emitters
        hazards = level.hazards.sortedGridPoints()
        hint = level.hint
    }
}

private extension Set where Element == GridPoint {
    func sortedGridPoints() -> [GridPoint] {
        sorted { lhs, rhs in
            if lhs.y != rhs.y { return lhs.y < rhs.y }
            return lhs.x < rhs.x
        }
    }
}

private enum SwiftCatalogMaterializer {
    static func source(levels: [LevelDefinition], count: Int, seed: UInt64, tierProfile: String) -> String {
        let exports = levels.map(LevelExport.init(level:))
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try! encoder.encode(exports)
        let json = String(data: data, encoding: .utf8)!

        return [
            "import Foundation",
            "",
            "// Generated by MagnetRelayLevelPlanner materialize-campaign --count \(count) --seed \(seed) --tier-profile \(tierProfile).",
            "// Local/test campaign levels; regenerate through the planner instead of hand editing.",
            "enum GeneratedLevelCatalog {",
            "    static let levels: [LevelDefinition] = loadLevels()",
            "",
            "    private static func loadLevels() -> [LevelDefinition] {",
            "        guard let data = campaignJSON.data(using: .utf8),",
            "              let levels = try? JSONDecoder().decode([LevelDefinition].self, from: data)",
            "        else {",
            "            fatalError(\"Generated campaign catalog failed to decode\")",
            "        }",
            "        return levels",
            "    }",
            "",
            "    private static let campaignJSON = #\"\"\"",
            json,
            "\"\"\"#",
            "}",
            ""
        ].joined(separator: "\n")
    }
}

do {
    try PlannerCLI.run()
} catch ExitCode.failure {
    exit(1)
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
