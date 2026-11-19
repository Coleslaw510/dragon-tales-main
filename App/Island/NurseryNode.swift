import SpriteKit

/// One egg on the nest: wobbles when ready, shows a small countdown until then.
final class EggNode: SKNode {
    static let side: CGFloat = 46

    let eggId: Int
    private let shell: SKSpriteNode
    private let timerLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    private let pill = SKShapeNode(rectOf: CGSize(width: 64, height: 24), cornerRadius: 12)

    /// `labelAbove` alternates timer pills above/below so neighbours don't overlap.
    init(egg: EggSave, species: DragonSpecies?, labelAbove: Bool) {
        eggId = egg.id
        let tex = species.map { Catalog.shared.eggTexture($0) } ?? Catalog.shared.texture("dragons/egg_rare.png")
        shell = SKSpriteNode(texture: tex, size: CGSize(width: EggNode.side, height: EggNode.side))
        super.init()
        name = "egg"
        shell.anchorPoint = CGPoint(x: 0.5, y: 0.15)
        addChild(shell)
        pill.fillColor = SKColor(white: 0, alpha: 0.6)
        pill.strokeColor = .clear
        pill.zPosition = 30
        timerLabel.fontSize = 15
        timerLabel.verticalAlignmentMode = .center
        timerLabel.zPosition = 31
        addChild(pill)
        addChild(timerLabel)
        setLabelAbove(labelAbove)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) not used") }

    func setLabelAbove(_ above: Bool) {
        let y: CGFloat = above ? EggNode.side + 10 : -30
        pill.position = CGPoint(x: 0, y: y)
        timerLabel.position = pill.position
    }

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

/// The nursery building (hatchery art, shifted back-left) with a nest beside it at the
/// front-right. Eggs sit in the nest; capacity comes from economy.json `hatchery.slots`.
final class NurseryNode: SKSpriteNode {
    static let side: CGFloat = 180
    static let anchor = CGPoint(x: 0.62, y: 0.40)
    static let nestOffset = CGPoint(x: 52, y: -62)

    let buildingId: Int
    private let nest: NestNode
    private let capacity: Int

    init(building: BuildingSave, capacity: Int) {
        let slots = max(1, capacity)
        buildingId = building.id
        self.capacity = slots
        nest = NestNode(slots: slots)
        super.init(texture: Catalog.shared.nurseryTexture, color: .clear,
                   size: CGSize(width: NurseryNode.side, height: NurseryNode.side))
        anchorPoint = NurseryNode.anchor
        name = "nursery"
        nest.position = NurseryNode.nestOffset
        nest.zPosition = 5
        addChild(nest)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) not used") }

    func sync(eggs: [EggSave], now: Date, catalog: Catalog) {
        var nodes: [Int: EggNode] = [:]
        for case let n as EggNode in nest.eggLayer.children { nodes[n.eggId] = n }
        let wanted = Set(eggs.map { $0.id })
        for (id, n) in nodes where !wanted.contains(id) { n.removeFromParent() }
        for (i, e) in eggs.prefix(capacity).enumerated() {
            let above = i % 2 == 1
            let node: EggNode
            if let existing = nodes[e.id] {
                node = existing
                node.setLabelAbove(above)
            } else {
                node = EggNode(egg: e, species: catalog.species(e.speciesId), labelAbove: above)
                nest.eggLayer.addChild(node)
                node.run(Effects.tapBounce())
            }
            let slot = nest.slotPosition(i)
            node.position = slot
            node.zPosition = 10 - slot.y / 10
            node.update(readyAt: e.readyAt, now: now)
        }
    }
}

/// Nest composed from shapes (no nest art ships): woven back rim + bowl, eggs, front rim.
final class NestNode: SKNode {
    static let spacing: CGFloat = 34
    let eggLayer = SKNode()
    private let perRow: Int
    let width: CGFloat

    init(slots: Int) {
        perRow = min(4, slots)
        width = CGFloat(perRow) * NestNode.spacing + 34
        super.init()
        let rows = (slots + perRow - 1) / perRow
        let h: CGFloat = 40 + CGFloat(rows - 1) * 14
        let dark = SKColor(red: 0.42, green: 0.27, blue: 0.13, alpha: 1)
        let mid = SKColor(red: 0.62, green: 0.42, blue: 0.20, alpha: 1)
        let light = SKColor(red: 0.80, green: 0.62, blue: 0.34, alpha: 1)

        let shadow = SKShapeNode(ellipseOf: CGSize(width: width + 16, height: h * 0.7))
        shadow.fillColor = SKColor(white: 0, alpha: 0.22)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -h * 0.35)
        addChild(shadow)
        let back = SKShapeNode(ellipseOf: CGSize(width: width, height: h))
        back.fillColor = mid
        back.strokeColor = dark
        back.lineWidth = 3
        addChild(back)
        let bowl = SKShapeNode(ellipseOf: CGSize(width: width - 22, height: h - 16))
        bowl.fillColor = dark
        bowl.strokeColor = .clear
        bowl.position = CGPoint(x: 0, y: 3)
        bowl.zPosition = 1
        addChild(bowl)
        eggLayer.zPosition = 2
        addChild(eggLayer)

        // Front rim: lower half of the nest drawn over the eggs, with twig strokes.
        let front = SKShapeNode(path: Self.lowerHalf(width: width, height: h))
        front.fillColor = mid
        front.strokeColor = dark
        front.lineWidth = 3
        front.zPosition = 20
        addChild(front)
        let twigs = CGMutablePath()
        let n = Int(width / 14)
        for i in 0..<n {
            let x = -width / 2 + 10 + CGFloat(i) * 14
            let y = -h * 0.18 - CGFloat(i % 3) * 4
            twigs.move(to: CGPoint(x: x - 8, y: y + 3))
            twigs.addLine(to: CGPoint(x: x + 10, y: y - 5))
        }
        let twigNode = SKShapeNode(path: twigs)
        twigNode.strokeColor = light
        twigNode.lineWidth = 2.5
        twigNode.lineCap = .round
        twigNode.zPosition = 21
        addChild(twigNode)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) not used") }

    private static func lowerHalf(width w: CGFloat, height h: CGFloat) -> CGPath {
        let p = CGMutablePath()
        p.move(to: CGPoint(x: -w / 2, y: 0))
        p.addCurve(to: CGPoint(x: w / 2, y: 0),
                   control1: CGPoint(x: -w / 2, y: -h * 0.68), control2: CGPoint(x: w / 2, y: -h * 0.68))
        p.addCurve(to: CGPoint(x: -w / 2, y: 0),
                   control1: CGPoint(x: w * 0.3, y: -h * 0.22), control2: CGPoint(x: -w * 0.3, y: -h * 0.22))
        p.closeSubpath()
        return p
    }

    /// Egg base position: rows of up to 4, later rows sit further back.
    func slotPosition(_ i: Int) -> CGPoint {
        let row = i / perRow
        let col = i % perRow
        let x = (CGFloat(col) - CGFloat(perRow - 1) / 2) * NestNode.spacing + (row % 2 == 1 ? NestNode.spacing / 2 : 0)
        return CGPoint(x: x, y: -6 + CGFloat(row) * 14)
    }
}
