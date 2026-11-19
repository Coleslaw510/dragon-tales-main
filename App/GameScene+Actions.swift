import SpriteKit

/// Gameplay flows: shop purchases, habitat placement, hatching, collecting, selection info.
extension GameScene {
    // MARK: Modals

    func presentModal(_ m: ModalPanel) {
        closeModal()
        modal = m
        m.onClose = { [weak self] in self?.closeModal() }
        cam.addChild(m)
        m.setScale(0.9)
        m.alpha = 0
        m.run(SKAction.group([SKAction.scale(to: 1, duration: 0.12), SKAction.fadeIn(withDuration: 0.12)]))
    }

    func closeModal() {
        modal?.removeFromParent()
        modal = nil
    }

    // MARK: Shop

    func openShop(tab: ShopOverlay.Tab) {
        guard placement == nil else { return }
        let shop = ShopOverlay(sceneSize: size, catalog: catalog, gold: state.gold, tab: tab)
        shop.onBuyEgg = { [weak self] s in self?.buyEgg(s) }
        shop.onBuyHabitat = { [weak self] e in self?.buyHabitat(e) }
        presentModal(shop)
    }

    func buyEgg(_ s: DragonSpecies) {
        switch state.buyEgg(s, now: Date()) {
        case .ok:
            closeModal()
            tick()
            if let n = nurseryNode { Effects.bounce(n) }
            let needsHabitat = !state.habitats.contains(where: { s.elements.contains($0.element ?? "") })
            hud.toast(needsHabitat
                      ? "\(s.name) egg is in the Nursery. It needs a \(catalog.elementName(s.element)) Habitat to hatch."
                      : "\(s.name) egg is in the Nursery")
            select(.nursery)
            save()
        case .notEnoughGold:
            hud.toast("Not enough gold")
        case .nurseryFull:
            hud.toast("The Nursery is full (\(catalog.nurserySlots) eggs)")
        }
    }

    func buyHabitat(_ element: String) {
        guard state.canAfford(catalog.habitatCost) else {
            hud.toast("Not enough gold")
            return
        }
        closeModal()
        startPlacement(element)
    }

    // MARK: Placement

    func startPlacement(_ element: String) {
        guard let p = PlacementController(element: element, grid: grid,
                                          occupied: state.occupiedCells(grid: grid),
                                          near: cam.position, world: world) else {
            hud.toast("No free space on the island")
            return
        }
        placement = p
        select(nil)
        hud.setPlacementMode(true, element: catalog.elementName(element))
        hud.confirmButton.isEnabled = p.isValid
    }

    func confirmPlacement() {
        guard let p = placement, p.isValid else {
            hud.toast("Can't place it there")
            return
        }
        guard let b = state.placeHabitat(element: p.element, col: p.col, row: p.row, now: Date()) else {
            hud.toast("Not enough gold")
            return
        }
        endPlacement()
        addBuildingNode(b)
        if let node = habitatNodes[b.id] { Effects.bounce(node) }
        hud.setGold(state.gold)
        hud.toast("\(catalog.elementName(p.element)) Habitat placed")
        select(.habitat(b.id))
        save()
    }

    func cancelPlacement() {
        endPlacement()
    }

    private func endPlacement() {
        placement?.remove()
        placement = nil
        hud.setPlacementMode(false, element: nil)
    }

    // MARK: Nursery and hatching

    func firstReadyEgg() -> Int? {
        let now = Date()
        return state.data.eggs.first(where: { $0.readyAt <= now })?.id
    }

    func tapEgg(_ id: Int) {
        guard let egg = state.egg(id), let s = catalog.species(egg.speciesId) else { return }
        select(.egg(id))
        let remaining = egg.readyAt.timeIntervalSinceNow
        guard remaining <= 0 else {
            hud.toast("\(s.name) hatches in \(Format.countdown(remaining))")
            return
        }
        let elementName = catalog.elementName(s.element)
        let options = state.compatibleHabitats(for: s)
        if options.isEmpty {
            let text = "\(s.name) needs a \(elementName) Habitat with free space. Buy one, then tap the egg again."
            let buttons: [Prompts.ButtonSpec] = [
                (title: "Later", color: Palette.muted, action: { [weak self] in self?.closeModal() }),
                (title: "Open Shop", color: Palette.accent, action: { [weak self] in self?.openShop(tab: .habitats) })
            ]
            presentModal(Prompts.message(title: "Needs a home", text: text, buttons: buttons, sceneSize: size))
            return
        }
        let capacity = catalog.habitatCapacity
        let rows: [(id: Int, title: String)] = options.map { b in
            (id: b.id, title: "\(elementName) Habitat  \(state.dragons(inHabitat: b.id).count)/\(capacity)")
        }
        presentModal(Prompts.habitatPicker(species: s, options: rows, sceneSize: size,
                                           onPick: { [weak self] habitatId in
                                               self?.hatch(eggId: id, into: habitatId)
                                           }))
    }

    func hatch(eggId: Int, into habitatId: Int) {
        closeModal()
        guard let d = state.hatch(eggId: eggId, habitatId: habitatId, now: Date()) else {
            hud.toast("Couldn't hatch that egg")
            return
        }
        tick()
        refreshHabitat(habitatId)
        if let h = habitatNodes[habitatId] { Effects.bounce(h) }
        hud.toast("\(catalog.species(d.speciesId)?.name ?? "Dragon") hatched!")
        select(.dragon(d.id))
        save()
    }

    // MARK: Income

    func collect(_ h: HabitatNode) {
        let amount = state.collect(habitatId: h.buildingId, now: Date())
        guard amount > 0 else { return }
        Effects.coinPop(amount: amount, at: CGPoint(x: h.position.x, y: h.position.y + 130), in: world)
        let from = cam.convert(h.position, from: world)
        Effects.flyCoins(count: min(8, 1 + amount / 25), from: from, to: hud.coinTarget,
                         in: cam, texture: catalog.coinTexture) { [weak self] in
            self?.hud.bumpGold()
        }
        h.setStored(state.storedGold(habitatId: h.buildingId))
        hud.setGold(state.gold)
        save()
    }

    // MARK: Selection

    func select(_ s: Selection?) {
        selection = s
        refreshInfo()
    }

    func refreshInfo() {
        guard let sel = selection else {
            hud.showInfo(nil)
            return
        }
        hud.showInfo(infoText(sel))
    }

    private func infoText(_ sel: Selection) -> String? {
        switch sel {
        case .habitat(let id):
            guard let b = state.building(id) else { return nil }
            let count = state.dragons(inHabitat: id).count
            let rate = Format.gold(Int(state.goldPerHour(habitatId: id)))
            let stored = Format.gold(state.storedGold(habitatId: id))
            let cap = Format.gold(Int(catalog.habitatStorageCap))
            let header = "\(catalog.elementName(b.element ?? "")) Habitat · \(count)/\(catalog.habitatCapacity) dragons"
            return header + "\n\(rate) gold/hr · stored \(stored)/\(cap)"
        case .nursery:
            let eggs = state.data.eggs
            var text = "Nursery · \(eggs.count)/\(catalog.nurserySlots) eggs"
            if let next = eggs.map({ $0.readyAt }).min() {
                let r = next.timeIntervalSinceNow
                text += r <= 0 ? "\nAn egg is ready. Tap it to hatch!" : "\nNext egg ready in \(Format.countdown(r))"
            } else {
                text += "\nBuy eggs in the Shop"
            }
            return text
        case .dragon(let id):
            guard let d = state.dragon(id), let sp = catalog.species(d.speciesId) else { return nil }
            let rate = Format.gold(Int(catalog.goldPerHour(sp)))
            return "\(sp.name) · \(catalog.elementName(sp.element)) · \(sp.rarity)\n\(rate) gold/hr"
        case .egg(let id):
            guard let e = state.egg(id), let sp = catalog.species(e.speciesId) else { return nil }
            let r = e.readyAt.timeIntervalSinceNow
            return r <= 0 ? "\(sp.name) egg · ready!\nTap to hatch" : "\(sp.name) egg\nHatches in \(Format.countdown(r))"
        }
    }
}
