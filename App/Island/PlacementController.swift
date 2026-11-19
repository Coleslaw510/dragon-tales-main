import SpriteKit

/// Placement mode for a newly bought habitat: a ghost that snaps to the grid,
/// green when the 2x2 footprint is free and on grass, red otherwise.
final class PlacementController {
    let element: String
    let ghost: SKSpriteNode
    private let overlay: SKShapeNode
    private let grid: IslandGrid
    private let occupied: Set<GridCell>
    private(set) var col: Int
    private(set) var row: Int
    private(set) var isValid = false

    init?(element: String, grid: IslandGrid, occupied: Set<GridCell>, near p: CGPoint, world: SKNode) {
        guard let spot = grid.nearestFree(to: p, occupied: occupied) else { return nil }
        self.element = element
        self.grid = grid
        self.occupied = occupied
        col = spot.col
        row = spot.row

        let g = SKSpriteNode(texture: Catalog.shared.habitatTexture(element),
                             size: CGSize(width: HabitatNode.side, height: HabitatNode.side))
        g.alpha = 0.8
        g.zPosition = 400
        g.colorBlendFactor = 0.35
        ghost = g

        let o = SKShapeNode(path: grid.overlayPath())
        o.strokeColor = SKColor(white: 1, alpha: 0.45)
        o.fillColor = SKColor(white: 1, alpha: 0.06)
        o.lineWidth = 2
        o.zPosition = 5
        overlay = o

        world.addChild(o)
        world.addChild(g)
        refresh()
        g.run(Effects.tapBounce())
    }

    func move(toWorld p: CGPoint) {
        let o = grid.origin(near: p)
        guard o.col != col || o.row != row else { return }
        col = o.col
        row = o.row
        refresh()
    }

    /// `p` in world coordinates (the ghost's parent).
    func contains(_ p: CGPoint) -> Bool { ghost.contains(p) }

    func remove() {
        ghost.removeFromParent()
        overlay.removeFromParent()
    }

    private func refresh() {
        ghost.position = grid.center(col: col, row: row)
        isValid = grid.canPlace(col: col, row: row, occupied: occupied)
        ghost.color = isValid ? .green : .red
    }
}
