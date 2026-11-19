import SpriteKit

/// A hatched dragon living in a habitat. The container wanders (random walk with pauses)
/// inside `bounds`; the child sprite bobs and flips to face the walking direction.
final class DragonNode: SKNode {
    /// Shipped dragon art faces left.
    static let artFacesLeft = true
    static let walkSpeed: CGFloat = 26

    let dragonId: Int
    let speciesId: String
    let body: SKSpriteNode
    private var bounds = CGRect.zero

    init(dragon: DragonSave, species: DragonSpecies, size: CGFloat) {
        dragonId = dragon.id
        speciesId = species.id
        body = SKSpriteNode(texture: Catalog.shared.dragonTexture(species), color: .clear,
                            size: CGSize(width: size, height: size))
        super.init()
        name = "dragon"
        addChild(body)
        body.run(Effects.idleBob(), withKey: "bob")
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) not used") }

    /// Starts wandering inside `rect` (parent coordinates).
    func startWandering(in rect: CGRect) {
        bounds = rect
        removeAction(forKey: "wander")
        pauseThenStep(initial: true)
    }

    private func pauseThenStep(initial: Bool = false) {
        let pause = initial ? Double.random(in: 0.2...1.5) : Double.random(in: 1.2...3.5)
        run(SKAction.sequence([SKAction.wait(forDuration: pause), SKAction.run { [weak self] in self?.step() }]), withKey: "wander")
    }

    private func step() {
        guard bounds.width > 0 || bounds.height > 0 else { return }
        let target = CGPoint(x: CGFloat.random(in: bounds.minX...bounds.maxX),
                             y: CGFloat.random(in: bounds.minY...bounds.maxY))
        let dx = target.x - position.x
        let dy = target.y - position.y
        let dist = (dx * dx + dy * dy).squareRoot()
        guard dist > 6 else {
            pauseThenStep()
            return
        }
        face(dx)
        zPosition = 10 - target.y / 10
        let move = SKAction.move(to: target, duration: Double(dist / DragonNode.walkSpeed))
        move.timingMode = .easeInEaseOut
        run(SKAction.sequence([move, SKAction.run { [weak self] in self?.pauseThenStep() }]), withKey: "wander")
    }

    private func face(_ dx: CGFloat) {
        guard abs(dx) > 1 else { return }
        let movingRight = dx > 0
        let flip = movingRight == DragonNode.artFacesLeft
        body.xScale = flip ? -abs(body.xScale) : abs(body.xScale)
    }
}
