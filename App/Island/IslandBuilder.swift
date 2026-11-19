import SpriteKit

/// Island backdrop (island_base + drifting clouds) and building nodes from state.
extension GameScene {
    static let islandWidth: CGFloat = 1700

    func buildBackdrop() {
        let tex = catalog.texture("tiles/island_base.png")
        let ts = tex.size()
        let aspect = ts.width > 0 ? ts.height / ts.width : 0.76
        let island = SKSpriteNode(texture: tex, size: CGSize(width: GameScene.islandWidth,
                                                            height: GameScene.islandWidth * aspect))
        // Align the grass top (about 36% down the image) with the grid center.
        island.position = CGPoint(x: 0, y: -0.145 * island.size.height)
        island.zPosition = -10
        island.name = "island"
        world.addChild(island)

        let spots: [(CGFloat, CGFloat)] = [(-1150, 560), (1100, 420), (-1000, -700),
                                           (1150, -520), (80, 960), (-250, -1100)]
        for (i, spot) in spots.enumerated() {
            let ctex = catalog.texture("tiles/cloud_\(i % 4 + 1).png")
            let cs = ctex.size()
            let cloud = SKSpriteNode(texture: ctex, size: CGSize(width: cs.width * 0.9, height: cs.height * 0.9))
            cloud.position = CGPoint(x: spot.0, y: spot.1)
            cloud.zPosition = -20
            cloud.alpha = 0.9
            let drift = SKAction.moveBy(x: i % 2 == 0 ? 140 : -140, y: 0, duration: 10 + Double(i))
            drift.timingMode = .easeInEaseOut
            cloud.run(.repeatForever(.sequence([drift, drift.reversed()])))
            world.addChild(cloud)
        }
    }

    func depth(_ p: CGPoint) -> CGFloat { 100 - p.y / 10 }

    func rebuildBuildings() {
        habitatNodes.values.forEach { $0.removeFromParent() }
        habitatNodes.removeAll()
        nurseryNode?.removeFromParent()
        nurseryNode = nil
        for b in state.data.buildings { addBuildingNode(b) }
    }

    func addBuildingNode(_ b: BuildingSave) {
        let pos = grid.center(col: b.col, row: b.row)
        switch b.kind {
        case .nursery:
            let n = NurseryNode(building: b)
            n.position = pos
            n.zPosition = depth(pos)
            world.addChild(n)
            nurseryNode = n
            n.sync(eggs: state.data.eggs, now: Date(), catalog: catalog)
        case .habitat:
            let h = HabitatNode(building: b)
            h.position = pos
            h.zPosition = depth(pos)
            world.addChild(h)
            habitatNodes[b.id] = h
            refreshHabitat(b.id)
        }
    }

    func refreshHabitat(_ id: Int) {
        guard let node = habitatNodes[id] else { return }
        node.setDragons(state.dragons(inHabitat: id), catalog: catalog)
        node.setStored(state.storedGold(habitatId: id))
    }
}
