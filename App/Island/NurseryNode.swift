import SpriteKit

/// One egg in the nursery: wobbles when ready, shows a countdown until then.
final class EggNode: SKNode {
    let eggId: Int
    private let shell: SKSpriteNode
    private let timerLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")

    init(egg: EggSave, species: DragonSpecies?) {
        eggId = egg.id
        let tex = species.map { Catalog.shared.eggTexture($0) } ?? Catalog.shared.texture("dragons/egg_rare.png")
        shell = SKSpriteNode(texture: tex, size: CGSize(width: 74, height: 74))
        super.init()
        name = "egg"
        addChild(shell)
        let pill = SKShapeNode(rectOf: CGSize(width: 110, height: 40), cornerRadius: 20)
        pill.fillColor = SKColor(white: 0, alpha: 0.55)
        pill.strokeColor = .clear
        pill.position = CGPoint(x: 0, y: -58)
        pill.zPosition = 1
        addChild(pill)
        timerLabel.fontSize = 28
        timerLabel.verticalAlignmentMode = .center
        timerLabel.position = CGPoint(x: 0, y: -58)
        timerLabel.zPosition = 2
        addChild(timerLabel)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) not used") }

    func update(readyAt: Date, now: Date) {
        let remaining = readyAt.timeIntervalSince(now)
        if remaining <= 0 {
            timerLabel.text = "Hatch!"
            timerLabel.fontColor = SKColor(red: 1, green: 0.88, blue: 0.3, alpha: 1)
            if shell.action(forKey: "wobble") == nil {
                shell.run(Effects.wobble(), withKey: "wobble")
            }
        } else {
            timerLabel.text = Format.countdown(remaining)
            timerLabel.fontColor = .white
            if shell.action(forKey: "wobble") != nil {
                shell.removeAction(forKey: "wobble")
                shell.zRotation = 0
            }
        }
    }
}

/// The nursery building (hatchery art). Bought eggs sit in front of it.
final class NurseryNode: SKSpriteNode {
    static let side: CGFloat = 210

    let buildingId: Int
    private let eggLayer = SKNode()

    init(building: BuildingSave) {
        buildingId = building.id
        super.init(texture: Catalog.shared.nurseryTexture, color: .clear,
                   size: CGSize(width: NurseryNode.side, height: NurseryNode.side))
        name = "nursery"
        eggLayer.zPosition = 5
        addChild(eggLayer)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) not used") }

    func sync(eggs: [EggSave], now: Date, catalog: Catalog) {
        var nodes: [Int: EggNode] = [:]
        for case let n as EggNode in eggLayer.children { nodes[n.eggId] = n }
        let wanted = Set(eggs.map { $0.id })
        for (id, n) in nodes where !wanted.contains(id) { n.removeFromParent() }
        for (i, e) in eggs.enumerated() {
            let node: EggNode
            if let existing = nodes[e.id] {
                node = existing
            } else {
                node = EggNode(egg: e, species: catalog.species(e.speciesId))
                eggLayer.addChild(node)
                node.run(Effects.tapBounce())
            }
            node.position = slotPosition(i, count: eggs.count)
            node.update(readyAt: e.readyAt, now: now)
        }
    }

    private func slotPosition(_ i: Int, count: Int) -> CGPoint {
        let spacing: CGFloat = 92
        let x = (CGFloat(i) - CGFloat(count - 1) / 2) * spacing
        return CGPoint(x: x, y: -NurseryNode.side / 2 - 6)
    }
}
