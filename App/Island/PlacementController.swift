import SpriteKit

/// Placement mode shared by new habitats, new caves, and moving placed buildings: a ghost that snaps
/// to the grid over a footprint marker, green when the 2x2 footprint is free and on grass,
/// red otherwise.
final class PlacementController {
    enum Purpose: Equatable {
        case newHabitat(String)
        case newCave
        case move(Int)
    }

    let purpose: Purpose
    let ghost: SKSpriteNode
    private let overlay: SKShapeNode
    private let marker: SKShapeNode
    private let grid: IslandGrid
    private let occupied: Set<GridCell>
    private(set) var col: Int
    private(set) var row: Int
    private(set) var isValid = false

    var element: String? {
        if case .newHabitat(let e) = purpose { return e }
        return nil
    }

    var movingId: Int? {
        if case .move(let id) = purpose { return id }
        return nil
    }

    /// `start` is the current spot when moving; otherwise the nearest free spot to `near`.
    init?(purpose: Purpose, texture: SKTexture, size: CGSize, anchor: CGPoint = CGPoint(x: 0.5, y: 0.5),
          grid: IslandGrid, occupied: Set<GridCell>, start: (col: Int, row: Int)? = nil,
          near p: CGPoint, world: SKNode) {
        guard let spot = start ?? grid.nearestFree(to: p, occupied: occupied) else { return nil }
        self.purpose = purpose
        self.grid = grid
        self.occupied = occupied
        col = spot.col
        row = spot.row

        let g = SKSpriteNode(texture: texture, size: size)
        g.anchorPoint = anchor
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

        let side = grid.cell * CGFloat(IslandGrid.footprintSize)
        let m = SKShapeNode(rectOf: CGSize(width: side - 6, height: side - 6), cornerRadius: 12)
        m.lineWidth = 4
        m.zPosition = 399
        marker = m

        world.addChild(o)
        world.addChild(m)
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
    func contains(_ p: CGPoint) -> Bool { ghost.contains(p) || marker.contains(p) }

    func remove() {
        ghost.removeFromParent()
        overlay.removeFromParent()
        marker.removeFromParent()
    }

    private func refresh() {
        let c = grid.center(col: col, row: row)
        ghost.position = c
        marker.position = c
        isValid = grid.canPlace(col: col, row: row, occupied: occupied)
        ghost.color = isValid ? .green : .red
        let tint: SKColor = isValid ? .green : .red
        marker.strokeColor = tint.withAlphaComponent(0.9)
        marker.fillColor = tint.withAlphaComponent(0.22)
    }
}
