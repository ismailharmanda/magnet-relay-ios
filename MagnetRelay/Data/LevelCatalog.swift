import Foundation

enum LevelCatalog {
    static let levels: [LevelDefinition] = handcraftedLevels + GeneratedLevelCatalog.levels

    static let handcraftedLevels: [LevelDefinition] = [
        LevelDefinition(
            id: 1,
            title: "First Charge",
            labCode: "MR-01",
            columns: 6,
            rows: 7,
            parPulses: 2,
            magnets: [
                MagnetDefinition(id: "m-cyan", position: GridPoint(x: 1, y: 3), polarity: .cyan, movable: true)
            ],
            blocks: [
                BlockDefinition(id: "b-cyan", position: GridPoint(x: 4, y: 3), polarity: .cyan, mass: 1.0)
            ],
            targets: [
                TargetDefinition(id: "t-cyan", position: GridPoint(x: 2, y: 3), polarity: .cyan)
            ],
            barriers: [],
            emitters: [],
            hazards: [],
            hint: "Drag the cyan magnet onto the left lane and release a pulse to pull the glass block home."
        ),
        LevelDefinition(
            id: 2,
            title: "Two Tone Gate",
            labCode: "MR-02",
            columns: 6,
            rows: 7,
            parPulses: 4,
            magnets: [
                MagnetDefinition(id: "m-cyan", position: GridPoint(x: 0, y: 2), polarity: .cyan, movable: true),
                MagnetDefinition(id: "m-amber", position: GridPoint(x: 5, y: 4), polarity: .amber, movable: true)
            ],
            blocks: [
                BlockDefinition(id: "b-cyan", position: GridPoint(x: 4, y: 2), polarity: .cyan, mass: 1.0),
                BlockDefinition(id: "b-amber", position: GridPoint(x: 1, y: 4), polarity: .amber, mass: 1.0)
            ],
            targets: [
                TargetDefinition(id: "t-cyan", position: GridPoint(x: 2, y: 2), polarity: .cyan),
                TargetDefinition(id: "t-amber", position: GridPoint(x: 3, y: 4), polarity: .amber)
            ],
            barriers: [GridPoint(x: 2, y: 3), GridPoint(x: 3, y: 3)],
            emitters: [],
            hazards: [],
            hint: "Use each magnet only on matching charged glass. The center baffles split the lanes."
        ),
        LevelDefinition(
            id: 3,
            title: "Offset Corridor",
            labCode: "MR-03",
            columns: 6,
            rows: 7,
            parPulses: 5,
            magnets: [
                MagnetDefinition(id: "m-cyan", position: GridPoint(x: 1, y: 5), polarity: .cyan, movable: true)
            ],
            blocks: [
                BlockDefinition(id: "b-cyan", position: GridPoint(x: 1, y: 1), polarity: .cyan, mass: 1.1)
            ],
            targets: [
                TargetDefinition(id: "t-cyan", position: GridPoint(x: 1, y: 4), polarity: .cyan)
            ],
            barriers: [GridPoint(x: 0, y: 3), GridPoint(x: 2, y: 3), GridPoint(x: 3, y: 3)],
            emitters: [
                FieldEmitterDefinition(id: "e-cyan", position: GridPoint(x: 4, y: 5), direction: .south, polarity: .cyan)
            ],
            hazards: [],
            hint: "The target is above the block; keep the magnet in the same column for clean line of sight."
        ),
        LevelDefinition(
            id: 4,
            title: "Glass Fork",
            labCode: "MR-04",
            columns: 6,
            rows: 7,
            parPulses: 6,
            magnets: [
                MagnetDefinition(id: "m-cyan", position: GridPoint(x: 0, y: 1), polarity: .cyan, movable: true),
                MagnetDefinition(id: "m-violet", position: GridPoint(x: 5, y: 5), polarity: .violet, movable: true)
            ],
            blocks: [
                BlockDefinition(id: "b-cyan", position: GridPoint(x: 4, y: 1), polarity: .cyan, mass: 1.0),
                BlockDefinition(id: "b-violet", position: GridPoint(x: 1, y: 5), polarity: .violet, mass: 1.0)
            ],
            targets: [
                TargetDefinition(id: "t-cyan", position: GridPoint(x: 2, y: 1), polarity: .cyan),
                TargetDefinition(id: "t-violet", position: GridPoint(x: 3, y: 5), polarity: .violet)
            ],
            barriers: [GridPoint(x: 2, y: 2), GridPoint(x: 3, y: 4), GridPoint(x: 2, y: 4), GridPoint(x: 3, y: 2)],
            emitters: [],
            hazards: [GridPoint(x: 2, y: 3), GridPoint(x: 3, y: 3)],
            hint: "Avoid the red discharge cells; align the blocks from the outside lanes."
        ),
        LevelDefinition(
            id: 5,
            title: "Baffle Line",
            labCode: "MR-05",
            columns: 7,
            rows: 7,
            parPulses: 7,
            magnets: [
                MagnetDefinition(id: "m-amber", position: GridPoint(x: 6, y: 3), polarity: .amber, movable: true)
            ],
            blocks: [
                BlockDefinition(id: "b-amber-a", position: GridPoint(x: 1, y: 3), polarity: .amber, mass: 1.0),
                BlockDefinition(id: "b-amber-b", position: GridPoint(x: 3, y: 0), polarity: .amber, mass: 1.0)
            ],
            targets: [
                TargetDefinition(id: "t-amber-a", position: GridPoint(x: 4, y: 3), polarity: .amber),
                TargetDefinition(id: "t-amber-b", position: GridPoint(x: 3, y: 2), polarity: .amber)
            ],
            barriers: [GridPoint(x: 2, y: 3), GridPoint(x: 3, y: 4), GridPoint(x: 4, y: 4)],
            emitters: [],
            hazards: [],
            hint: "One block needs horizontal pull, the other needs vertical setup."
        ),
        LevelDefinition(
            id: 6,
            title: "Mirror Bay",
            labCode: "MR-06",
            columns: 7,
            rows: 7,
            parPulses: 8,
            magnets: [
                MagnetDefinition(id: "m-cyan", position: GridPoint(x: 0, y: 6), polarity: .cyan, movable: true),
                MagnetDefinition(id: "m-amber", position: GridPoint(x: 6, y: 0), polarity: .amber, movable: true)
            ],
            blocks: [
                BlockDefinition(id: "b-cyan", position: GridPoint(x: 5, y: 6), polarity: .cyan, mass: 1.1),
                BlockDefinition(id: "b-amber", position: GridPoint(x: 1, y: 0), polarity: .amber, mass: 1.1)
            ],
            targets: [
                TargetDefinition(id: "t-cyan", position: GridPoint(x: 2, y: 6), polarity: .cyan),
                TargetDefinition(id: "t-amber", position: GridPoint(x: 4, y: 0), polarity: .amber)
            ],
            barriers: [GridPoint(x: 3, y: 1), GridPoint(x: 3, y: 2), GridPoint(x: 3, y: 4), GridPoint(x: 3, y: 5)],
            emitters: [],
            hazards: [],
            hint: "Treat the board like two mirrored rails and solve each rail from its outer edge."
        ),
        LevelDefinition(
            id: 7,
            title: "Polarity Stack",
            labCode: "MR-07",
            columns: 7,
            rows: 8,
            parPulses: 9,
            magnets: [
                MagnetDefinition(id: "m-cyan", position: GridPoint(x: 1, y: 7), polarity: .cyan, movable: true),
                MagnetDefinition(id: "m-violet", position: GridPoint(x: 5, y: 7), polarity: .violet, movable: true)
            ],
            blocks: [
                BlockDefinition(id: "b-cyan", position: GridPoint(x: 1, y: 1), polarity: .cyan, mass: 1.0),
                BlockDefinition(id: "b-violet", position: GridPoint(x: 5, y: 1), polarity: .violet, mass: 1.0)
            ],
            targets: [
                TargetDefinition(id: "t-cyan", position: GridPoint(x: 1, y: 5), polarity: .cyan),
                TargetDefinition(id: "t-violet", position: GridPoint(x: 5, y: 5), polarity: .violet)
            ],
            barriers: [GridPoint(x: 3, y: 2), GridPoint(x: 3, y: 3), GridPoint(x: 3, y: 4), GridPoint(x: 3, y: 5)],
            emitters: [
                FieldEmitterDefinition(id: "e-violet", position: GridPoint(x: 5, y: 6), direction: .south, polarity: .violet)
            ],
            hazards: [GridPoint(x: 3, y: 6)],
            hint: "Each color owns a column. Do not drag a magnet into the center discharge."
        ),
        LevelDefinition(
            id: 8,
            title: "Relay Crossing",
            labCode: "MR-08",
            columns: 7,
            rows: 8,
            parPulses: 10,
            magnets: [
                MagnetDefinition(id: "m-cyan", position: GridPoint(x: 0, y: 3), polarity: .cyan, movable: true),
                MagnetDefinition(id: "m-amber", position: GridPoint(x: 6, y: 4), polarity: .amber, movable: true)
            ],
            blocks: [
                BlockDefinition(id: "b-cyan", position: GridPoint(x: 6, y: 3), polarity: .cyan, mass: 1.0),
                BlockDefinition(id: "b-amber", position: GridPoint(x: 0, y: 4), polarity: .amber, mass: 1.0)
            ],
            targets: [
                TargetDefinition(id: "t-cyan", position: GridPoint(x: 3, y: 3), polarity: .cyan),
                TargetDefinition(id: "t-amber", position: GridPoint(x: 3, y: 4), polarity: .amber)
            ],
            barriers: [GridPoint(x: 3, y: 1), GridPoint(x: 3, y: 2), GridPoint(x: 3, y: 5), GridPoint(x: 3, y: 6)],
            emitters: [],
            hazards: [],
            hint: "The safe crossing is the center pair. Pull both blocks inward without blocking the other lane."
        ),
        LevelDefinition(
            id: 9,
            title: "Hazard Halo",
            labCode: "MR-09",
            columns: 7,
            rows: 8,
            parPulses: 11,
            magnets: [
                MagnetDefinition(id: "m-violet", position: GridPoint(x: 3, y: 7), polarity: .violet, movable: true)
            ],
            blocks: [
                BlockDefinition(id: "b-violet-a", position: GridPoint(x: 3, y: 0), polarity: .violet, mass: 1.0),
                BlockDefinition(id: "b-violet-b", position: GridPoint(x: 0, y: 4), polarity: .violet, mass: 1.0)
            ],
            targets: [
                TargetDefinition(id: "t-violet-a", position: GridPoint(x: 3, y: 5), polarity: .violet),
                TargetDefinition(id: "t-violet-b", position: GridPoint(x: 2, y: 4), polarity: .violet)
            ],
            barriers: [GridPoint(x: 1, y: 4), GridPoint(x: 4, y: 4), GridPoint(x: 5, y: 4)],
            emitters: [],
            hazards: [GridPoint(x: 3, y: 3), GridPoint(x: 3, y: 6)],
            hint: "The vertical lane has discharge cells. Use the side block first, then move the top magnet carefully."
        ),
        LevelDefinition(
            id: 10,
            title: "Tri-Core",
            labCode: "MR-10",
            columns: 7,
            rows: 8,
            parPulses: 12,
            magnets: [
                MagnetDefinition(id: "m-cyan", position: GridPoint(x: 0, y: 7), polarity: .cyan, movable: true),
                MagnetDefinition(id: "m-amber", position: GridPoint(x: 6, y: 7), polarity: .amber, movable: true),
                MagnetDefinition(id: "m-violet", position: GridPoint(x: 3, y: 0), polarity: .violet, movable: true)
            ],
            blocks: [
                BlockDefinition(id: "b-cyan", position: GridPoint(x: 0, y: 1), polarity: .cyan, mass: 1.0),
                BlockDefinition(id: "b-amber", position: GridPoint(x: 6, y: 1), polarity: .amber, mass: 1.0),
                BlockDefinition(id: "b-violet", position: GridPoint(x: 3, y: 6), polarity: .violet, mass: 1.0)
            ],
            targets: [
                TargetDefinition(id: "t-cyan", position: GridPoint(x: 0, y: 4), polarity: .cyan),
                TargetDefinition(id: "t-amber", position: GridPoint(x: 6, y: 4), polarity: .amber),
                TargetDefinition(id: "t-violet", position: GridPoint(x: 3, y: 3), polarity: .violet)
            ],
            barriers: [
                GridPoint(x: 2, y: 2), GridPoint(x: 4, y: 2),
                GridPoint(x: 2, y: 5), GridPoint(x: 4, y: 5)
            ],
            emitters: [
                FieldEmitterDefinition(id: "e-core", position: GridPoint(x: 3, y: 7), direction: .south, polarity: .violet)
            ],
            hazards: [GridPoint(x: 1, y: 4)],
            hint: "Solve the outer colors first, then bring violet down the center lane without dragging into the side discharge."
        ),
        LevelDefinition(
            id: 11,
            title: "Compression Ring",
            labCode: "MR-11",
            columns: 8,
            rows: 8,
            parPulses: 14,
            magnets: [
                MagnetDefinition(id: "m-cyan", position: GridPoint(x: 0, y: 0), polarity: .cyan, movable: true),
                MagnetDefinition(id: "m-amber", position: GridPoint(x: 7, y: 7), polarity: .amber, movable: true)
            ],
            blocks: [
                BlockDefinition(id: "b-cyan", position: GridPoint(x: 7, y: 0), polarity: .cyan, mass: 1.15),
                BlockDefinition(id: "b-amber", position: GridPoint(x: 0, y: 7), polarity: .amber, mass: 1.15)
            ],
            targets: [
                TargetDefinition(id: "t-cyan", position: GridPoint(x: 4, y: 0), polarity: .cyan),
                TargetDefinition(id: "t-amber", position: GridPoint(x: 3, y: 7), polarity: .amber)
            ],
            barriers: [
                GridPoint(x: 2, y: 2), GridPoint(x: 3, y: 2), GridPoint(x: 4, y: 2), GridPoint(x: 5, y: 2),
                GridPoint(x: 2, y: 5), GridPoint(x: 3, y: 5), GridPoint(x: 4, y: 5), GridPoint(x: 5, y: 5)
            ],
            emitters: [],
            hazards: [GridPoint(x: 3, y: 3), GridPoint(x: 4, y: 4)],
            hint: "The top and bottom rails are safe. The middle ring blocks risky paths."
        ),
        LevelDefinition(
            id: 12,
            title: "Final Calibration",
            labCode: "MR-12",
            columns: 8,
            rows: 8,
            parPulses: 15,
            magnets: [
                MagnetDefinition(id: "m-cyan", position: GridPoint(x: 1, y: 7), polarity: .cyan, movable: true),
                MagnetDefinition(id: "m-amber", position: GridPoint(x: 6, y: 7), polarity: .amber, movable: true),
                MagnetDefinition(id: "m-violet", position: GridPoint(x: 4, y: 0), polarity: .violet, movable: true)
            ],
            blocks: [
                BlockDefinition(id: "b-cyan", position: GridPoint(x: 1, y: 1), polarity: .cyan, mass: 1.1),
                BlockDefinition(id: "b-amber", position: GridPoint(x: 6, y: 1), polarity: .amber, mass: 1.1),
                BlockDefinition(id: "b-violet", position: GridPoint(x: 4, y: 6), polarity: .violet, mass: 1.1)
            ],
            targets: [
                TargetDefinition(id: "t-cyan", position: GridPoint(x: 1, y: 5), polarity: .cyan),
                TargetDefinition(id: "t-amber", position: GridPoint(x: 6, y: 5), polarity: .amber),
                TargetDefinition(id: "t-violet", position: GridPoint(x: 4, y: 2), polarity: .violet)
            ],
            barriers: [
                GridPoint(x: 3, y: 2), GridPoint(x: 5, y: 2),
                GridPoint(x: 3, y: 5), GridPoint(x: 5, y: 5),
                GridPoint(x: 2, y: 3), GridPoint(x: 7, y: 3)
            ],
            emitters: [
                FieldEmitterDefinition(id: "e-cyan", position: GridPoint(x: 1, y: 6), direction: .south, polarity: .cyan),
                FieldEmitterDefinition(id: "e-amber", position: GridPoint(x: 6, y: 6), direction: .south, polarity: .amber)
            ],
            hazards: [GridPoint(x: 2, y: 4)],
            hint: "Outer columns first, then use the violet relay while staying clear of the side discharge."
        )
    ]

    static func level(id: Int) -> LevelDefinition {
        levels.first(where: { $0.id == id }) ?? levels[0]
    }
}
