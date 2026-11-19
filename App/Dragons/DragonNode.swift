import SpriteKit

/// A hatched dragon living in a habitat. Idle bob only (no feeding/leveling yet).
final class DragonNode: SKSpriteNode {
    let dragonId: Int
    let speciesId: String

    init(dragon: DragonSave, species: DragonSpecies, size: CGFloat) {
        dragonId = dragon.id
        speciesId = species.id
        super.init(texture: Catalog.shared.dragonTexture(species), color: .clear,
                   size: CGSize(width: size, height: size))
        name = "dragon"
        run(Effects.idleBob(), withKey: "bob")
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) not used") }
}
