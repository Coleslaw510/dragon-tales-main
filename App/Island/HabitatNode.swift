import SpriteKit

/// A placed habitat: element sprite, up to `capacity` wandering dragons, and a coin badge
/// showing stored gold once it is at least 50% of the cap.
final class HabitatNode: SKSpriteNode {
    static let side: CGFloat = 200
    static let slots: [CGPoint] = [CGPoint(x: -48, y: 22), CGPoint(x: 48, y: 22),
                                   CGPoint(x: -48, y: -34), CGPoint(x: 48, y: -34)]
    /// Area dragon centers may wander in (habitat-local), keeping sprites on the habitat.
    static let wanderBounds = CGRect(x: -52, y: -40, width: 104, height: 66)

    let buildingId: Int
    let element: String
    private let dragonLayer = SKNode()
    private let badge = SKNode()
    private let badgeLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")

    init(building: BuildingSave) {
        buildingId = building.id
        element = building.element ?? "fire"
        super.init(texture: Catalog.shared.habitatTexture(element), color: .clear,
                   size: CGSize(width: HabitatNode.side, height: HabitatNode.side))
        name = "habitat"
        dragonLayer.zPosition = 2
        addChild(dragonLayer)

        let pill = SKShapeNode(rectOf: CGSize(width: 130, height: 50), cornerRadius: 25)
        pill.fillColor = SKColor(white: 0, alpha: 0.55)
        pill.strokeColor = SKColor(red: 1, green: 0.85, blue: 0.3, alpha: 1)
        pill.lineWidth = 3
        badge.addChild(pill)
        let coin = SKSpriteNode(texture: Catalog.shared.coinTexture, size: CGSize(width: 44, height: 44))
        coin.position = CGPoint(x: -40, y: 0)
        coin.zPosition = 1
        badge.addChild(coin)
        badgeLabel.fontSize = 30
        badgeLabel.fontColor = .white
        badgeLabel.verticalAlignmentMode = .center
        badgeLabel.horizontalAlignmentMode = .left
        badgeLabel.position = CGPoint(x: -14, y: 0)
        badgeLabel.zPosition = 1
        badge.addChild(badgeLabel)
        badge.position = CGPoint(x: 0, y: HabitatNode.side / 2 + 18)
        badge.zPosition = 20
        badge.isHidden = true
        addChild(badge)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) not used") }

    func setDragons(_ dragons: [DragonSave], catalog: Catalog) {
        let existing = Set(dragonLayer.children.compactMap { ($0 as? DragonNode)?.dragonId })
        let wanted = Set(dragons.map { $0.id })
        guard existing != wanted else { return }
        dragonLayer.removeAllChildren()
        for (i, d) in dragons.enumerated() {
            guard let s = catalog.species(d.speciesId) else { continue }
            let node = DragonNode(dragon: d, species: s, size: 96)
            let slot = HabitatNode.slots[i % HabitatNode.slots.count]
            node.position = slot
            node.zPosition = 10 - slot.y / 10
            dragonLayer.addChild(node)
            node.startWandering(in: HabitatNode.wanderBounds)
        }
    }

    /// The coin badge appears once stored gold reaches half the habitat's cap.
    func setStored(_ amount: Int, cap: Double) {
        let show = cap > 0 && amount >= 1 && Double(amount) >= cap * 0.5
        badge.isHidden = !show
        badgeLabel.text = Format.gold(amount)
        if show, badge.action(forKey: "pulse") == nil {
            let up = SKAction.scale(to: 1.08, duration: 0.6)
            up.timingMode = .easeInEaseOut
            let down = SKAction.scale(to: 1.0, duration: 0.6)
            down.timingMode = .easeInEaseOut
            badge.run(.repeatForever(.sequence([up, down])), withKey: "pulse")
        } else if !show {
            badge.removeAction(forKey: "pulse")
        }
    }
}
