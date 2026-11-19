import SpriteKit

/// A placed Breeding Cave (shipped grove art) with a status pill above it:
/// hidden when idle, a countdown while breeding, and the egg + "Ready!" when done.
final class CaveNode: SKSpriteNode {
    static let side: CGFloat = 190

    let buildingId: Int
    private let badge = SKNode()
    private let pill = SKShapeNode(rectOf: CGSize(width: 150, height: 48), cornerRadius: 24)
    private let icon = SKSpriteNode()
    private let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    private var shownSpecies: String?

    init(building: BuildingSave) {
        buildingId = building.id
        super.init(texture: Catalog.shared.caveTexture, color: .clear,
                   size: CGSize(width: CaveNode.side, height: CaveNode.side))
        name = "cave"
        pill.fillColor = SKColor(white: 0, alpha: 0.55)
        pill.lineWidth = 3
        badge.addChild(pill)
        icon.size = CGSize(width: 38, height: 38)
        icon.position = CGPoint(x: -48, y: 2)
        icon.zPosition = 1
        badge.addChild(icon)
        label.fontSize = 24
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .left
        label.position = CGPoint(x: -24, y: 0)
        label.zPosition = 1
        badge.addChild(label)
        badge.position = CGPoint(x: 0, y: CaveNode.side / 2 + 14)
        badge.zPosition = 20
        badge.isHidden = true
        addChild(badge)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) not used") }

    func sync(breed: BreedSave?, now: Date, catalog: Catalog) {
        guard let br = breed, let s = catalog.species(br.speciesId) else {
            badge.isHidden = true
            badge.removeAction(forKey: "pulse")
            shownSpecies = nil
            return
        }
        badge.isHidden = false
        if shownSpecies != s.id {
            shownSpecies = s.id
            icon.texture = catalog.eggTexture(s)
        }
        let left = br.readyAt.timeIntervalSince(now)
        if left <= 0 {
            label.text = "Ready!"
            pill.strokeColor = Palette.go
            if badge.action(forKey: "pulse") == nil {
                let up = SKAction.scale(to: 1.08, duration: 0.6)
                up.timingMode = .easeInEaseOut
                let down = SKAction.scale(to: 1.0, duration: 0.6)
                down.timingMode = .easeInEaseOut
                badge.run(.repeatForever(.sequence([up, down])), withKey: "pulse")
            }
        } else {
            label.text = Format.countdown(left)
            pill.strokeColor = Palette.gem
            badge.removeAction(forKey: "pulse")
        }
    }
}
