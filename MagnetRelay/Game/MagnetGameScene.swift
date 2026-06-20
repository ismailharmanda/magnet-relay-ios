import GameplayKit
import SpriteKit
import UIKit

final class MagnetGameScene: SKScene, SKPhysicsContactDelegate {
    var onStateChanged: ((GameState) -> Void)?
    var onSolved: ((GameState) -> Void)?
    var onRetry: ((GameState) -> Void)?

    private(set) var level: LevelDefinition
    private(set) var gameState: GameState
    var tuning = PhysicsTuning.premiumSlice

    private let sceneStateMachine = GKStateMachine(states: [
        LabIdleState(),
        LabDraggingState(),
        LabAnimatingState(),
        LabSolvedState()
    ])

    private var boardOrigin = CGPoint.zero
    private var tileSize: CGFloat = 44
    private var boardNode = SKNode()
    private var effectNode = SKNode()
    private var guideNode = SKNode()
    private var cameraRig = SKCameraNode()
    private var magnetNodes: [String: SKNode] = [:]
    private var blockNodes: [String: SKNode] = [:]
    private var targetNodes: [String: SKNode] = [:]
    private var selectedMagnetID: String?
    private var selectedMagnetStart: GridPoint?
    private var selectedMagnetPhysics: DragPhysicsSnapshot?
    private var didNotifySolved = false
    private var showsHitboxes = false

    private var solvedPreviewEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains("-MagnetRelaySolvedPreview")
    }

    init(size: CGSize, level: LevelDefinition) {
        self.level = level
        gameState = GameState(level: level)
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = UIColor(red: 0.02, green: 0.026, blue: 0.038, alpha: 1)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        view.isMultipleTouchEnabled = false
        sceneStateMachine.enter(LabIdleState.self)
        rebuildScene()
        if solvedPreviewEnabled {
            solveForPreview()
        }
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard size.width > 1, size.height > 1 else { return }
        rebuildScene()
        if solvedPreviewEnabled {
            solveForPreview()
        }
    }

    override func update(_ currentTime: TimeInterval) {
        sceneStateMachine.update(deltaTime: currentTime)
    }

    func load(level newLevel: LevelDefinition) {
        level = newLevel
        gameState = GameState(level: newLevel)
        didNotifySolved = false
        sceneStateMachine.enter(LabIdleState.self)
        rebuildScene()
        onStateChanged?(gameState)
    }

    func resetLevel() {
        gameState.markRetry(level: level)
        didNotifySolved = false
        sceneStateMachine.enter(LabIdleState.self)
        rebuildScene()
        onRetry?(gameState)
        onStateChanged?(gameState)
    }

    func undo() -> Bool {
        guard gameState.restoreUndoSnapshot() else {
            Haptics.play(.invalidMove)
            return false
        }
        didNotifySolved = gameState.solved
        alignNodesToState(animated: true)
        sceneStateMachine.enter(LabIdleState.self)
        onStateChanged?(gameState)
        return true
    }

    func showHintPulse() {
        let flash = SKAction.sequence([
            .fadeAlpha(to: 0.15, duration: 0.12),
            .fadeAlpha(to: 1.0, duration: 0.18)
        ])
        for target in targetNodes.values {
            target.run(.repeat(flash, count: 3))
        }
    }

    func showSolvedPreview() {
        var blockIDsByPolarity = Dictionary(grouping: level.blocks, by: \.polarity)
        for target in level.targets {
            guard var blocks = blockIDsByPolarity[target.polarity], !blocks.isEmpty else { continue }
            let block = blocks.removeFirst()
            blockIDsByPolarity[target.polarity] = blocks
            gameState.blocks[block.id] = target.position
        }
        gameState.solved = true
        gameState.failed = false
        gameState.pulses = min(level.parPulses, max(1, level.targets.count))
        hideGuide()
        alignNodesToState(animated: false)
        targetLockCascade()
        onStateChanged?(gameState)
    }

    func setSlowMotion(_ enabled: Bool) {
        speed = enabled ? 0.45 : tuning.slowMotionScale
    }

    func setHitboxesVisible(_ visible: Bool) {
        showsHitboxes = visible
        for node in Array(blockNodes.values) + Array(magnetNodes.values) {
            node.childNode(withName: "hitbox")?.isHidden = !visible
        }
    }

    func setForceMultiplier(_ multiplier: Double) {
        tuning.magneticForce = PhysicsTuning.premiumSlice.magneticForce * CGFloat(multiplier)
    }

    private func rebuildScene() {
        removeAllChildren()
        magnetNodes.removeAll()
        blockNodes.removeAll()
        targetNodes.removeAll()

        cameraRig = SKCameraNode()
        camera = cameraRig
        cameraRig.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(cameraRig)

        addBackground()
        calculateBoardMetrics()

        boardNode = SKNode()
        boardNode.zPosition = 5
        addChild(boardNode)
        effectNode = SKNode()
        effectNode.zPosition = 80
        addChild(effectNode)

        drawBoard()
        drawTargets()
        drawHazards()
        drawBarriers()
        drawEmitters()
        drawBlocks()
        drawMagnets()
        alignNodesToState(animated: false)
        drawFirstLevelGuide()
    }

    private func addBackground() {
        let base = SKShapeNode(rectOf: size)
        base.position = CGPoint(x: size.width / 2, y: size.height / 2)
        base.fillColor = UIColor(red: 0.02, green: 0.026, blue: 0.038, alpha: 1)
        base.strokeColor = .clear
        base.zPosition = -20
        addChild(base)

        for index in 0..<9 {
            let y = CGFloat(index) / 8 * size.height
            let line = SKShapeNode(rectOf: CGSize(width: size.width * 1.25, height: 1.0))
            line.position = CGPoint(x: size.width / 2, y: y)
            line.fillColor = UIColor(red: 0.08, green: 0.18, blue: 0.19, alpha: 0.18)
            line.strokeColor = .clear
            line.zPosition = -10
            addChild(line)
        }
    }

    private func calculateBoardMetrics() {
        let horizontalInset: CGFloat = 20
        let topReserve = max(size.height * 0.24, 188)
        let bottomReserve = max(size.height * 0.16, 116)
        let usableHeight = max(size.height - topReserve - bottomReserve, 260)
        let widthTile = (size.width - horizontalInset * 2) / CGFloat(max(level.columns, 1))
        let heightTile = usableHeight / CGFloat(max(level.rows, 1))
        tileSize = min(widthTile, heightTile)
        let boardWidth = CGFloat(level.columns - 1) * tileSize
        let boardHeight = CGFloat(level.rows - 1) * tileSize
        boardOrigin = CGPoint(
            x: size.width / 2 - boardWidth / 2,
            y: bottomReserve + usableHeight / 2 - boardHeight / 2
        )
    }

    private func drawBoard() {
        let backplateSize = CGSize(width: CGFloat(level.columns) * tileSize + 20, height: CGFloat(level.rows) * tileSize + 20)
        let backplate = SKShapeNode(rectOf: backplateSize, cornerRadius: 16)
        backplate.position = CGPoint(
            x: boardOrigin.x + CGFloat(level.columns - 1) * tileSize / 2,
            y: boardOrigin.y + CGFloat(level.rows - 1) * tileSize / 2
        )
        backplate.fillColor = UIColor(red: 0.035, green: 0.047, blue: 0.058, alpha: 0.94)
        backplate.strokeColor = UIColor(red: 0.17, green: 0.64, blue: 0.70, alpha: 0.46)
        backplate.lineWidth = 1.4
        backplate.glowWidth = 2.4
        backplate.zPosition = -1
        boardNode.addChild(backplate)

        for cell in level.gridCells {
            let tile = SKShapeNode(rectOf: CGSize(width: tileSize * 0.86, height: tileSize * 0.86), cornerRadius: tileSize * 0.13)
            tile.position = point(for: cell)
            tile.fillColor = UIColor(red: 0.072, green: 0.092, blue: 0.108, alpha: 1)
            tile.strokeColor = UIColor(red: 0.18, green: 0.38, blue: 0.42, alpha: 0.58)
            tile.lineWidth = 0.95
            tile.glowWidth = 0.4
            tile.zPosition = 1
            boardNode.addChild(tile)
        }
    }

    private func drawTargets() {
        for target in level.targets {
            let color = SciFiTheme.uiColor(for: target.polarity)
            let node = makeInstrumentGlyph(
                name: "target:\(target.id)",
                glyph: .target,
                size: CGSize(width: tileSize * 0.76, height: tileSize * 0.76),
                color: color,
                glyphScale: 0.84,
                shadowAlpha: 0.36,
                glowAlpha: 0.12,
                zPosition: 10
            )
            node.position = point(for: target.position)
            targetNodes[target.id] = node
            boardNode.addChild(node)
        }
    }

    private func drawHazards() {
        for cell in level.hazards {
            let color = UIColor(red: 1.0, green: 0.25, blue: 0.32, alpha: 1)
            let node = makeInstrumentGlyph(
                glyph: .hazard,
                size: CGSize(width: tileSize * 0.70, height: tileSize * 0.70),
                color: color,
                glyphScale: 0.88,
                shadowAlpha: 0.42,
                glowAlpha: 0.18,
                zPosition: 13
            )
            node.position = point(for: cell)
            node.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: tileSize * 0.58, height: tileSize * 0.58))
            node.physicsBody?.isDynamic = false
            node.physicsBody?.categoryBitMask = CollisionCategory.hazard
            boardNode.addChild(node)
        }
    }

    private func drawBarriers() {
        for cell in level.barriers {
            let color = UIColor(red: 0.72, green: 0.82, blue: 0.86, alpha: 1)
            let node = makeInstrumentGlyph(
                glyph: .barrier,
                size: CGSize(width: tileSize * 0.74, height: tileSize * 0.74),
                color: color,
                glyphColor: UIColor(red: 0.86, green: 0.94, blue: 0.97, alpha: 1),
                glyphScale: 0.92,
                shadowAlpha: 0.34,
                glowAlpha: 0.04,
                zPosition: 20
            )
            node.position = point(for: cell)
            node.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: tileSize * 0.74, height: tileSize * 0.74))
            node.physicsBody?.isDynamic = false
            node.physicsBody?.categoryBitMask = CollisionCategory.barrier
            boardNode.addChild(node)
        }
    }

    private func drawEmitters() {
        for emitter in level.emitters {
            let color = SciFiTheme.uiColor(for: emitter.polarity)
            let node = makeInstrumentGlyph(
                glyph: .emitter,
                size: CGSize(width: tileSize * 0.58, height: tileSize * 0.58),
                color: color,
                glyphScale: 0.96,
                shadowAlpha: 0.34,
                glowAlpha: 0.12,
                zPosition: 18
            )
            node.position = point(for: emitter.position)

            let ray = SKShapeNode(rectOf: raySize(for: emitter.direction))
            ray.position = rayOffset(for: emitter.direction)
            ray.name = "emitterBeam"
            ray.fillColor = color.withAlphaComponent(0.26)
            ray.strokeColor = .clear
            ray.zPosition = -1
            node.addChild(ray)
            boardNode.addChild(node)
        }
    }

    private func raySize(for direction: Direction) -> CGSize {
        switch direction {
        case .north, .south:
            return CGSize(width: 3, height: tileSize * 0.52)
        case .east, .west:
            return CGSize(width: tileSize * 0.52, height: 3)
        }
    }

    private func rayOffset(for direction: Direction) -> CGPoint {
        let amount = tileSize * 0.32
        switch direction {
        case .north:
            return CGPoint(x: 0, y: amount)
        case .south:
            return CGPoint(x: 0, y: -amount)
        case .east:
            return CGPoint(x: amount, y: 0)
        case .west:
            return CGPoint(x: -amount, y: 0)
        }
    }

    private func drawBlocks() {
        for block in level.blocks {
            let color = SciFiTheme.uiColor(for: block.polarity)
            let bodySize = CGSize(width: tileSize * 0.74, height: tileSize * 0.74)
            let node = makeInstrumentGlyph(
                name: "block:\(block.id)",
                glyph: .chargedBlock,
                size: bodySize,
                color: color,
                glyphScale: 0.90,
                shadowAlpha: 0.38,
                glowAlpha: 0.16,
                zPosition: 45
            )
            node.physicsBody = SKPhysicsBody(rectangleOf: bodySize)
            node.physicsBody?.mass = CGFloat(block.mass)
            node.physicsBody?.linearDamping = tuning.linearDamping
            node.physicsBody?.angularDamping = tuning.angularDamping
            node.physicsBody?.friction = tuning.friction
            node.physicsBody?.restitution = tuning.restitution
            node.physicsBody?.categoryBitMask = CollisionCategory.block
            node.physicsBody?.collisionBitMask = CollisionCategory.barrier | CollisionCategory.block | CollisionCategory.magnet
            node.physicsBody?.contactTestBitMask = CollisionCategory.target | CollisionCategory.hazard | CollisionCategory.barrier
            addHitbox(to: node, size: bodySize)
            blockNodes[block.id] = node
            boardNode.addChild(node)
        }
    }

    private func drawMagnets() {
        for magnet in level.magnets {
            let color = SciFiTheme.uiColor(for: magnet.polarity)
            let node = makeInstrumentGlyph(
                name: "magnet:\(magnet.id)",
                glyph: .magnet,
                size: CGSize(width: tileSize * 0.84, height: tileSize * 0.84),
                color: color,
                glyphScale: 0.90,
                shadowAlpha: 0.42,
                glowAlpha: 0.18,
                zPosition: 60
            )

            node.physicsBody = SKPhysicsBody(circleOfRadius: tileSize * 0.40)
            node.physicsBody?.mass = tuning.magnetMass
            node.physicsBody?.linearDamping = tuning.linearDamping
            node.physicsBody?.angularDamping = tuning.angularDamping
            node.physicsBody?.isDynamic = true
            node.physicsBody?.allowsRotation = false
            node.physicsBody?.categoryBitMask = CollisionCategory.magnet
            node.physicsBody?.collisionBitMask = CollisionCategory.block | CollisionCategory.barrier
            addHitbox(to: node, size: CGSize(width: tileSize * 0.84, height: tileSize * 0.84))
            magnetNodes[magnet.id] = node
            boardNode.addChild(node)
        }
    }

    private func makeInstrumentGlyph(
        name: String? = nil,
        glyph: BoardGlyph,
        size: CGSize,
        color: UIColor,
        glyphColor: UIColor? = nil,
        glyphScale: CGFloat,
        shadowAlpha: CGFloat,
        glowAlpha: CGFloat,
        zPosition: CGFloat
    ) -> SKNode {
        let node = SKNode()
        node.name = name
        node.zPosition = zPosition

        let glyphSize = CGSize(width: min(size.width, size.height) * glyphScale, height: min(size.width, size.height) * glyphScale)
        let tint = glyphColor ?? color

        let glow = SKSpriteNode(imageNamed: glyph.assetName)
        glow.name = "glyphGlow"
        glow.texture?.filteringMode = .linear
        glow.color = color
        glow.colorBlendFactor = 1
        glow.alpha = glowAlpha
        glow.blendMode = .add
        glow.size = CGSize(width: glyphSize.width * 1.16, height: glyphSize.height * 1.16)
        glow.zPosition = 0
        node.addChild(glow)

        let shadow = SKSpriteNode(imageNamed: glyph.assetName)
        shadow.name = "glyphShadow"
        shadow.texture?.filteringMode = .linear
        shadow.color = .black
        shadow.colorBlendFactor = 1
        shadow.alpha = shadowAlpha
        shadow.position = CGPoint(x: tileSize * 0.022, y: -tileSize * 0.026)
        shadow.size = glyphSize
        shadow.zPosition = 1
        node.addChild(shadow)

        let glyphNode = SKSpriteNode(imageNamed: glyph.assetName)
        glyphNode.name = "glyph"
        glyphNode.texture?.filteringMode = .linear
        glyphNode.size = glyphSize
        glyphNode.color = tint
        glyphNode.colorBlendFactor = 1
        glyphNode.alpha = 0.96
        glyphNode.zPosition = 2
        node.addChild(glyphNode)

        return node
    }

    private func setInstrumentGlyphStyle(
        _ node: SKNode,
        color: UIColor,
        glyphColor: UIColor? = nil,
        accentAlpha: CGFloat,
        strokeAlpha: CGFloat,
        glowWidth: CGFloat,
        glyphAlpha: CGFloat
    ) {
        if let glow = node.childNode(withName: "glyphGlow") as? SKSpriteNode {
            glow.color = color
            glow.colorBlendFactor = 1
            glow.alpha = min(0.26, max(0.04, glowWidth * 0.055 + accentAlpha * 0.38))
        }
        if let glyph = node.childNode(withName: "glyph") as? SKSpriteNode {
            glyph.color = glyphColor ?? color
            glyph.colorBlendFactor = 1
            glyph.alpha = glyphAlpha
        }
    }

    private func drawFirstLevelGuide() {
        guideNode.removeFromParent()
        guard level.id == 1, gameState.moves == 0, gameState.pulses == 0, !gameState.solved,
              let magnet = level.magnets.first,
              let block = level.blocks.first(where: { $0.polarity == magnet.polarity }),
              let target = level.targets.first(where: { $0.polarity == block.polarity })
        else { return }

        guideNode = SKNode()
        guideNode.zPosition = 76
        effectNode.addChild(guideNode)

        let color = SciFiTheme.uiColor(for: magnet.polarity)
        let start = point(for: magnet.position)
        let end = point(for: block.position)
        let control = CGPoint(x: (start.x + end.x) / 2, y: start.y + tileSize * 0.52)

        let path = CGMutablePath()
        path.move(to: start)
        path.addQuadCurve(to: end, control: control)

        let line = SKShapeNode(path: path)
        line.strokeColor = color.withAlphaComponent(0.78)
        line.lineWidth = 3.4
        line.glowWidth = 13
        guideNode.addChild(line)
        line.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.35, duration: 0.55),
            .fadeAlpha(to: 1.0, duration: 0.55)
        ])))

        for index in 1...3 {
            let fraction = CGFloat(index) / 4.0
            let dot = SKShapeNode(circleOfRadius: tileSize * 0.075)
            dot.fillColor = color.withAlphaComponent(0.95)
            dot.strokeColor = .clear
            dot.glowWidth = 8
            dot.position = CGPoint(
                x: start.x + (end.x - start.x) * fraction,
                y: start.y + (end.y - start.y) * fraction + sin(fraction * .pi) * tileSize * 0.22
            )
            guideNode.addChild(dot)
            dot.run(.repeatForever(.sequence([
                .wait(forDuration: TimeInterval(index) * 0.10),
                .group([.scale(to: 1.65, duration: 0.35), .fadeAlpha(to: 0.25, duration: 0.35)]),
                .group([.scale(to: 1.0, duration: 0.22), .fadeAlpha(to: 1.0, duration: 0.22)])
            ])))
        }

        let targetPulse = SKShapeNode(circleOfRadius: tileSize * 0.48)
        targetPulse.position = point(for: target.position)
        targetPulse.fillColor = .clear
        targetPulse.strokeColor = SciFiTheme.uiColor(for: target.polarity).withAlphaComponent(0.75)
        targetPulse.lineWidth = 2.2
        targetPulse.glowWidth = 10
        guideNode.addChild(targetPulse)
        targetPulse.run(.repeatForever(.sequence([
            .group([.scale(to: 1.18, duration: 0.55), .fadeAlpha(to: 0.35, duration: 0.55)]),
            .group([.scale(to: 1.0, duration: 0.45), .fadeAlpha(to: 1.0, duration: 0.45)])
        ])))
    }

    private func hideGuide() {
        guard guideNode.parent != nil else { return }
        let fadingGuide = guideNode
        guideNode = SKNode()
        fadingGuide.run(.sequence([
            .fadeOut(withDuration: 0.16),
            .removeFromParent()
        ]))
    }

    private func solveForPreview() {
        var usedBlockIDs = Set<String>()
        for target in level.targets {
            guard let block = level.blocks.first(where: { block in
                block.polarity == target.polarity && !usedBlockIDs.contains(block.id)
            }) else { continue }
            usedBlockIDs.insert(block.id)
            gameState.blocks[block.id] = target.position
        }
        gameState.solved = WinValidator.isSolved(level: level, state: gameState)
        didNotifySolved = gameState.solved
        hideGuide()
        alignNodesToState(animated: false)
        if gameState.solved {
            sceneStateMachine.enter(LabSolvedState.self)
            targetLockCascade()
        }
        onStateChanged?(gameState)
    }

    private func addHitbox(to node: SKNode, size: CGSize) {
        let hitbox = SKShapeNode(rectOf: size)
        hitbox.name = "hitbox"
        hitbox.strokeColor = UIColor.white.withAlphaComponent(0.7)
        hitbox.lineWidth = 1
        hitbox.fillColor = .clear
        hitbox.isHidden = !showsHitboxes
        hitbox.zPosition = 100
        node.addChild(hitbox)
    }

    private func point(for cell: GridPoint) -> CGPoint {
        CGPoint(
            x: boardOrigin.x + CGFloat(cell.x) * tileSize,
            y: boardOrigin.y + CGFloat(cell.y) * tileSize
        )
    }

    private func alignNodesToState(animated: Bool) {
        for (id, cell) in gameState.magnets {
            guard let node = magnetNodes[id] else { continue }
            move(node, to: point(for: cell), animated: animated)
        }
        for (id, cell) in gameState.blocks {
            guard let node = blockNodes[id] else { continue }
            move(node, to: point(for: cell), animated: animated)
        }
        updateTargetLocks()
    }

    private func move(_ node: SKNode, to position: CGPoint, animated: Bool) {
        node.physicsBody?.velocity = .zero
        node.physicsBody?.angularVelocity = 0
        node.removeAction(forKey: "snap")
        if animated {
            let action = SKAction.move(to: position, duration: 0.18)
            action.timingMode = .easeOut
            node.run(action, withKey: "snap")
        } else {
            node.position = position
        }
    }

    private func updateTargetLocks() {
        for target in level.targets {
            guard let node = targetNodes[target.id] else { continue }
            let locked = level.blocks.contains { block in
                block.polarity == target.polarity && gameState.blocks[block.id] == target.position
            }
            let color = locked ? UIColor(red: 0.26, green: 0.90, blue: 0.55, alpha: 1) : SciFiTheme.uiColor(for: target.polarity)
            node.setScale(locked ? 1.12 : 1.0)
            node.alpha = locked ? 1.0 : 0.86
            setInstrumentGlyphStyle(
                node,
                color: color,
                accentAlpha: locked ? 0.20 : 0.13,
                strokeAlpha: locked ? 0.86 : 0.66,
                glowWidth: locked ? 2.2 : 1.1,
                glyphAlpha: locked ? 1.0 : 0.92
            )
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard sceneStateMachine.currentState is LabIdleState,
              let touch = touches.first,
              !gameState.solved
        else { return }
        hideGuide()
        let location = touch.location(in: self)
        guard let magnetID = magnetID(at: location),
              let node = magnetNodes[magnetID],
              let start = gameState.magnets[magnetID]
        else { return }

        beginDrag(magnetID: magnetID, node: node, start: start)
        Haptics.play(.magnetPickup)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard sceneStateMachine.currentState is LabDraggingState,
              let touch = touches.first,
              let selectedMagnetID,
              let node = magnetNodes[selectedMagnetID]
        else { return }
        node.position = touch.location(in: self)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        finishDrag(touches.first)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        finishDrag(nil)
    }

    private func magnetID(at location: CGPoint) -> String? {
        nodes(at: location).compactMap { node -> String? in
            var cursor: SKNode? = node
            while let current = cursor {
                if let name = current.name, name.hasPrefix("magnet:") {
                    return String(name.dropFirst("magnet:".count))
                }
                cursor = current.parent
            }
            return nil
        }.first
    }

    private func finishDrag(_ touch: UITouch?) {
        guard sceneStateMachine.currentState is LabDraggingState,
              let magnetID = selectedMagnetID,
              let node = magnetNodes[magnetID]
        else { return }
        let startCell = selectedMagnetStart
        defer {
            selectedMagnetID = nil
            selectedMagnetStart = nil
        }

        node.zPosition = 60

        let location = touch?.location(in: self) ?? node.position
        guard let snap = SnapLogic.snap(worldPosition: location, boardOrigin: boardOrigin, tileSize: tileSize, level: level, tuning: tuning),
              snap.accepted
        else {
            Haptics.play(.invalidMove)
            if let startCell {
                sceneStateMachine.enter(LabAnimatingState.self)
                settleDraggedMagnet(node, to: startCell) { [weak self] in
                    self?.sceneStateMachine.enter(LabIdleState.self)
                }
            } else {
                restoreDragPhysics(for: node)
                sceneStateMachine.enter(LabIdleState.self)
            }
            return
        }

        let relocate = MagnetRuleEngine.relocateMagnet(magnetID, to: snap.cell, level: level, state: &gameState)
        switch relocate {
        case .success:
            Haptics.play(.magnetDrop)
            onStateChanged?(gameState)
            sceneStateMachine.enter(LabAnimatingState.self)
            settleDraggedMagnet(node, to: snap.cell) { [weak self] in
                self?.run(.sequence([
                    .wait(forDuration: 0.04),
                    .run { [weak self] in
                        self?.freezeBoardPhysics()
                        self?.pulse(magnetID: magnetID)
                    }
                ]))
            }
        case .failure:
            Haptics.play(.invalidMove)
            if let startCell {
                sceneStateMachine.enter(LabAnimatingState.self)
                settleDraggedMagnet(node, to: startCell) { [weak self] in
                    self?.sceneStateMachine.enter(LabIdleState.self)
                }
            } else {
                restoreDragPhysics(for: node)
                sceneStateMachine.enter(LabIdleState.self)
            }
        }
    }

    private func beginDrag(magnetID: String, node: SKNode, start: GridPoint) {
        selectedMagnetID = magnetID
        selectedMagnetStart = start
        freezeBoardPhysics()
        cacheAndDisableDragPhysics(for: node)
        node.zPosition = 90
        node.removeAllActions()
        node.run(SKAction.scale(to: 1.14, duration: 0.08))
        sceneStateMachine.enter(LabDraggingState.self)
    }

    private func cacheAndDisableDragPhysics(for node: SKNode) {
        guard let body = node.physicsBody else { return }
        selectedMagnetPhysics = DragPhysicsSnapshot(
            isDynamic: body.isDynamic,
            allowsRotation: body.allowsRotation,
            collisionBitMask: body.collisionBitMask,
            contactTestBitMask: body.contactTestBitMask,
            fieldBitMask: body.fieldBitMask
        )
        body.velocity = .zero
        body.angularVelocity = 0
        body.collisionBitMask = 0
        body.contactTestBitMask = 0
        body.fieldBitMask = 0
        body.isDynamic = false
        body.allowsRotation = false
    }

    private func restoreDragPhysics(for node: SKNode) {
        guard let body = node.physicsBody else {
            selectedMagnetPhysics = nil
            return
        }
        if let snapshot = selectedMagnetPhysics {
            body.isDynamic = snapshot.isDynamic
            body.allowsRotation = snapshot.allowsRotation
            body.collisionBitMask = snapshot.collisionBitMask
            body.contactTestBitMask = snapshot.contactTestBitMask
            body.fieldBitMask = snapshot.fieldBitMask
        }
        body.velocity = .zero
        body.angularVelocity = 0
        selectedMagnetPhysics = nil
    }

    private func settleDraggedMagnet(_ node: SKNode, to cell: GridPoint, completion: @escaping () -> Void) {
        let target = point(for: cell)
        node.physicsBody?.velocity = .zero
        node.physicsBody?.angularVelocity = 0
        node.removeAction(forKey: "snap")

        let moveAction = SKAction.move(to: target, duration: 0.16)
        moveAction.timingMode = .easeOut
        let scale = SKAction.scale(to: 1.0, duration: 0.10)
        let restore = SKAction.run { [weak self, weak node] in
            guard let self, let node else { return }
            self.restoreDragPhysics(for: node)
            self.freezeBoardPhysics()
            completion()
        }
        node.run(.sequence([.group([moveAction, scale]), restore]), withKey: "snap")
    }

    private func freezeBoardPhysics() {
        for node in Array(blockNodes.values) + Array(magnetNodes.values) {
            node.physicsBody?.velocity = .zero
            node.physicsBody?.angularVelocity = 0
        }
    }

#if DEBUG
    func debugRebuildForTesting() {
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        sceneStateMachine.enter(LabIdleState.self)
        rebuildScene()
    }

    func debugBeginDrag(magnetID: String) -> Bool {
        guard sceneStateMachine.currentState is LabIdleState,
              let node = magnetNodes[magnetID],
              let start = gameState.magnets[magnetID]
        else { return false }
        beginDrag(magnetID: magnetID, node: node, start: start)
        return true
    }

    func debugMoveSelectedMagnet(to cell: GridPoint) {
        guard let selectedMagnetID, let node = magnetNodes[selectedMagnetID] else { return }
        node.position = point(for: cell)
        freezeBoardPhysics()
    }

    func debugCancelDragForTesting() {
        guard let selectedMagnetID,
              let node = magnetNodes[selectedMagnetID],
              let start = selectedMagnetStart
        else { return }
        node.position = point(for: start)
        node.setScale(1.0)
        node.zPosition = 60
        restoreDragPhysics(for: node)
        freezeBoardPhysics()
        self.selectedMagnetID = nil
        selectedMagnetStart = nil
        sceneStateMachine.enter(LabIdleState.self)
    }

    func debugBlockPosition(id: String) -> CGPoint? {
        blockNodes[id]?.position
    }

    func debugMagnetPhysics(id: String) -> (isDynamic: Bool, collisionBitMask: UInt32, contactTestBitMask: UInt32)? {
        guard let body = magnetNodes[id]?.physicsBody else { return nil }
        return (body.isDynamic, body.collisionBitMask, body.contactTestBitMask)
    }

    func debugWorldPoint(for cell: GridPoint) -> CGPoint {
        point(for: cell)
    }
#endif

    private func pulse(magnetID: String) {
        guard !gameState.solved else { return }
        sceneStateMachine.enter(LabAnimatingState.self)
        Haptics.play(.pulseCharge)

        let resolution = MagnetRuleEngine.planPulse(magnetID: magnetID, level: level, state: gameState, tuning: tuning)
        MagnetRuleEngine.applyPulse(resolution, level: level, state: &gameState)
        onStateChanged?(gameState)
        animatePulse(resolution)
    }

    private func animatePulse(_ resolution: PulseResolution) {
        drawChargeBurst(at: resolution.magnetPosition, polarity: level.magnets.first(where: { $0.id == resolution.magnetID })?.polarity ?? .cyan)

        let duration: TimeInterval = resolution.hasMotion ? 0.38 : 0.18
        for move in resolution.moves {
            guard let node = blockNodes[move.blockID] else { continue }
            let from = point(for: move.from)
            let to = point(for: move.to)
            let impulse = MagnetForceResolver.forceVector(from: move.from, toward: resolution.magnetPosition, polarityMatches: true, tuning: tuning)
            node.physicsBody?.applyImpulse(impulse)
            drawFieldArc(from: resolution.magnetPosition, to: move.from, polarity: move.polarity)
            node.position = from
            let overshoot = CGPoint(
                x: to.x + (to.x - from.x) * 0.09,
                y: to.y + (to.y - from.y) * 0.09
            )
            let accelerate = SKAction.move(to: overshoot, duration: duration * 0.72)
            accelerate.timingMode = .easeIn
            let snap = SKAction.move(to: to, duration: duration * 0.28)
            snap.timingMode = .easeOut
            let rotate = SKAction.rotate(byAngle: CGFloat.random(in: -0.10...0.10), duration: duration)
            node.run(.group([.sequence([accelerate, snap]), rotate]), withKey: "blockPulse")
        }

        run(.sequence([
            .wait(forDuration: duration + 0.10),
            .run { [weak self] in
                self?.finishPulseAnimation()
            }
        ]))
    }

    private func finishPulseAnimation() {
        alignNodesToState(animated: true)
        if gameState.failed {
            cameraShake(intensity: 5)
            Haptics.play(.invalidMove)
        }
        if gameState.solved {
            notifySolvedIfNeeded()
        } else {
            Haptics.play(.blockImpact)
            sceneStateMachine.enter(LabIdleState.self)
        }
    }

    private func notifySolvedIfNeeded() {
        guard !didNotifySolved else { return }
        didNotifySolved = true
        sceneStateMachine.enter(LabSolvedState.self)
        targetLockCascade()
        cameraShake(intensity: 3)
        Haptics.play(.puzzleSolved)
        onSolved?(gameState)
        onStateChanged?(gameState)
    }

    private func drawChargeBurst(at cell: GridPoint, polarity: ChargePolarity) {
        let color = SciFiTheme.uiColor(for: polarity)
        let ring = SKShapeNode(circleOfRadius: tileSize * 0.36)
        ring.position = point(for: cell)
        ring.strokeColor = color.withAlphaComponent(0.9)
        ring.lineWidth = 3
        ring.glowWidth = 16
        ring.fillColor = .clear
        ring.zPosition = 90
        effectNode.addChild(ring)
        ring.run(.sequence([
            .group([
                .scale(to: 2.8, duration: 0.38),
                .fadeOut(withDuration: 0.38)
            ]),
            .removeFromParent()
        ]))
    }

    private func drawFieldArc(from magnet: GridPoint, to block: GridPoint, polarity: ChargePolarity) {
        let color = SciFiTheme.uiColor(for: polarity)
        let path = CGMutablePath()
        let start = point(for: magnet)
        let end = point(for: block)
        let midpoint = CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2 + tileSize * 0.20)
        path.move(to: start)
        path.addQuadCurve(to: end, control: midpoint)
        let arc = SKShapeNode(path: path)
        arc.strokeColor = color.withAlphaComponent(0.92)
        arc.lineWidth = 3.2
        arc.glowWidth = 13
        arc.zPosition = 91
        effectNode.addChild(arc)
        arc.run(.sequence([
            .fadeOut(withDuration: 0.28),
            .removeFromParent()
        ]))
    }

    private func targetLockCascade() {
        let solvedColor = UIColor(red: 0.26, green: 0.90, blue: 0.55, alpha: 1)
        for (index, node) in targetNodes.values.enumerated() {
            let delay = TimeInterval(index) * 0.08
            let pulse = SKAction.sequence([
                .wait(forDuration: delay),
                .group([
                    .scale(to: 1.36, duration: 0.14),
                    .fadeAlpha(to: 1.0, duration: 0.14)
                ]),
                .scale(to: 1.12, duration: 0.18)
            ])
            node.run(pulse)
            setInstrumentGlyphStyle(
                node,
                color: solvedColor,
                accentAlpha: 0.22,
                strokeAlpha: 0.90,
                glowWidth: 2.6,
                glyphAlpha: 1.0
            )
        }

        let bloom = SKShapeNode(circleOfRadius: tileSize)
        bloom.position = CGPoint(
            x: boardOrigin.x + CGFloat(level.columns - 1) * tileSize / 2,
            y: boardOrigin.y + CGFloat(level.rows - 1) * tileSize / 2
        )
        bloom.strokeColor = solvedColor.withAlphaComponent(0.70)
        bloom.lineWidth = 3
        bloom.glowWidth = 18
        bloom.fillColor = .clear
        bloom.zPosition = 95
        effectNode.addChild(bloom)
        bloom.run(.sequence([
            .group([
                .scale(to: max(CGFloat(level.columns), CGFloat(level.rows)) * 0.72, duration: 0.62),
                .fadeOut(withDuration: 0.62)
            ]),
            .removeFromParent()
        ]))
    }

    private func cameraShake(intensity: CGFloat) {
        let original = cameraRig.position
        let actions = (0..<6).map { _ in
            SKAction.move(
                to: CGPoint(
                    x: original.x + CGFloat.random(in: -intensity...intensity),
                    y: original.y + CGFloat.random(in: -intensity...intensity)
                ),
                duration: 0.025
            )
        }
        cameraRig.run(.sequence(actions + [.move(to: original, duration: 0.03)]))
    }
}

private struct DragPhysicsSnapshot {
    var isDynamic: Bool
    var allowsRotation: Bool
    var collisionBitMask: UInt32
    var contactTestBitMask: UInt32
    var fieldBitMask: UInt32
}

private enum BoardGlyph {
    case magnet
    case target
    case emitter
    case barrier
    case hazard
    case chargedBlock

    var assetName: String {
        switch self {
        case .magnet: return "TablerMagnet"
        case .target: return "TablerTarget"
        case .emitter: return "TablerBroadcast"
        case .barrier: return "TablerBarrierBlock"
        case .hazard: return "TablerShieldBolt"
        case .chargedBlock: return "TablerCircuitBattery"
        }
    }
}

private final class LabIdleState: GKState {}
private final class LabDraggingState: GKState {}
private final class LabAnimatingState: GKState {}
private final class LabSolvedState: GKState {}
