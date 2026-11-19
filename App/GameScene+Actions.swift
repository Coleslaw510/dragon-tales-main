import SpriteKit

/// Gameplay flows: shop, Dragon Book, gem speed-ups, hatching, collecting, selection info.
/// Placement and move mode live in Island/GameScene+Placement.swift.
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

    /// Opens the shop menu, or straight into one section.
    func openShop(section: ShopOverlay.Section? = nil) {
        guard placement == nil else { return }
        let shop = ShopOverlay(sceneSize: size, catalog: catalog, gold: state.gold, section: section)
        shop.onBuyEgg = { [weak self] s in self?.buyEgg(s) }
        shop.onBuyHabitat = { [weak self] e in self?.buyHabitat(e) }
        shop.onUnavailable = { [weak self] text in self?.hud.toast(text) }
        presentModal(shop)
    }

    func openBook() {
        guard placement == nil else { return }
        presentModal(DragonBook(sceneSize: size, catalog: catalog, discovered: state.discoveredSpecies))
    }

    // MARK: Timers (gem speed-up)

    /// The timer the selection shows a speed-up button for, if any.
    func selectedTimer(now: Date) -> TimerRef? {
        switch selection {
        case .egg(let id)?:
            return state.remaining(.egg(id), now: now) > 0 ? .egg(id) : nil
        case .nursery?:
            return state.nextIncubatingEgg(now: now)
        default:
            return nil
        }
    }

    func speedUpSelected() {
        let now = Date()
        guard let t = selectedTimer(now: now) else { return }
        let cost = state.skipCost(t, now: now)
        switch state.speedUp(t, now: now) {
        case .ok:
            hud.bumpGems()
            hud.toast("Sped up for \(cost) gems")
            tick()
            if let n = nurseryNode { Effects.bounce(n) }
            save()
        case .notEnoughGems:
            hud.toast("Not enough gems (need \(cost), have \(state.gems))")
            Effects.bounce(hud.gemIcon)
        case .finished:
            refreshInfo()
        }
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
                (title: "Open Shop", color: Palette.accent, action: { [weak self] in self?.openShop(section: .habitats) })
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
        h.setStored(state.storedGold(habitatId: h.buildingId), cap: state.storageCap(habitatId: h.buildingId))
        hud.setGold(state.gold)
        save()
    }

    // MARK: Selection

    func select(_ s: Selection?) {
        selection = s
        refreshInfo()
    }

    func refreshInfo() {
        let now = Date()
        let timer = selectedTimer(now: now)
        let cost = timer.map { state.skipCost($0, now: now) }
        hud.setSpeedUp(cost: cost, affordable: (cost ?? 0) <= state.gems)
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
            let cap = Format.gold(Int(state.storageCap(habitatId: id)))
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
