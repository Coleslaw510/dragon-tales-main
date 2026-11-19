import SpriteKit
import UIKit

/// Placement flows: placing a newly bought habitat, and move mode (long-press a placed
/// building, drag it to a free spot, Confirm saves / Cancel restores).
extension GameScene {
    static let longPressSeconds: TimeInterval = 0.5

    // MARK: New habitat

    func startPlacement(_ element: String) {
        guard let p = PlacementController(purpose: .newHabitat(element), texture: catalog.habitatTexture(element),
                                          size: CGSize(width: HabitatNode.side, height: HabitatNode.side),
                                          grid: grid, occupied: state.occupiedCells(grid: grid),
                                          near: cam.position, world: world) else {
            hud.toast("No free space on the island")
            return
        }
        beginPlacement(p, hint: "Drag the \(catalog.elementName(element)) Habitat, then Confirm")
    }

    // MARK: Move mode

    /// Placed building (habitat or nursery) under a world point.
    func buildingNode(at p: CGPoint) -> (id: Int, node: SKSpriteNode)? {
        var best: (id: Int, node: SKSpriteNode)?
        for n in world.nodes(at: p) {
            var current: SKNode? = n
            while let node = current {
                if let h = node as? HabitatNode {
                    if best == nil || h.zPosition > best!.node.zPosition { best = (h.buildingId, h) }
                } else if let ns = node as? NurseryNode {
                    if best == nil || ns.zPosition > best!.node.zPosition { best = (ns.buildingId, ns) }
                }
                current = node.parent
            }
        }
        return best
    }

    func startMove(buildingId id: Int, touchWorld: CGPoint) {
        guard placement == nil, modal == nil, let b = state.building(id) else { return }
        let texture: SKTexture
        let size: CGSize
        var anchor = CGPoint(x: 0.5, y: 0.5)
        switch b.kind {
        case .habitat:
            texture = catalog.habitatTexture(b.element ?? "fire")
            size = CGSize(width: HabitatNode.side, height: HabitatNode.side)
        case .nursery:
            texture = catalog.nurseryTexture
            size = CGSize(width: NurseryNode.side, height: NurseryNode.side)
            anchor = NurseryNode.anchor
        }
        guard let p = PlacementController(purpose: .move(id), texture: texture, size: size, anchor: anchor,
                                          grid: grid, occupied: state.occupiedCells(grid: grid, excluding: id),
                                          start: (b.col, b.row), near: .zero, world: world) else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        node(forBuilding: id)?.alpha = 0.35
        beginPlacement(p, hint: "Drag to a free spot, then Confirm")
        draggingGhost = true
        isPanning = false
        dragOffset = CGPoint(x: p.ghost.position.x - touchWorld.x, y: p.ghost.position.y - touchWorld.y)
    }

    func node(forBuilding id: Int) -> SKNode? {
        if let h = habitatNodes[id] { return h }
        if let n = nurseryNode, n.buildingId == id { return n }
        return nil
    }

    // MARK: Confirm / cancel

    private func beginPlacement(_ p: PlacementController, hint: String) {
        placement = p
        select(nil)
        hud.setPlacementMode(true, hint: hint)
        hud.confirmButton.isEnabled = p.isValid
    }

    func confirmPlacement() {
        guard let p = placement, p.isValid else {
            hud.toast("Can't place it there")
            return
        }
        switch p.purpose {
        case .newHabitat(let element):
            guard let b = state.placeHabitat(element: element, col: p.col, row: p.row, now: Date()) else {
                hud.toast("Not enough gold")
                return
            }
            endPlacement()
            addBuildingNode(b)
            if let placed = habitatNodes[b.id] { Effects.bounce(placed) }
            hud.setGold(state.gold)
            hud.toast("\(catalog.elementName(element)) Habitat placed")
            select(.habitat(b.id))
        case .move(let id):
            state.moveBuilding(id, col: p.col, row: p.row)
            endPlacement()
            if let moved = node(forBuilding: id) {
                let pos = grid.center(col: p.col, row: p.row)
                moved.position = pos
                moved.zPosition = depth(pos)
                moved.alpha = 1
                Effects.bounce(moved)
            }
            hud.toast("Moved")
        }
        save()
    }

    func cancelPlacement() {
        if let id = placement?.movingId { node(forBuilding: id)?.alpha = 1 }
        endPlacement()
    }

    private func endPlacement() {
        placement?.remove()
        placement = nil
        hud.setPlacementMode(false, hint: nil)
    }
}
