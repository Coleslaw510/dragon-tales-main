import SpriteKit

/// Breeding Cave flows: buy, tap (pick parents / timer / collect), sync, and info text.
/// Placement of a new cave is in Island/GameScene+Placement.swift.
extension GameScene {
    func buyCave() {
        guard state.canAfford(CaveRules.cost) else {
            hud.toast("Not enough gold")
            return
        }
        closeModal()
        startCavePlacement()
    }

    func syncCaves(now: Date) {
        for (id, node) in caveNodes {
            node.sync(breed: state.breed(inCave: id), now: now, catalog: catalog)
        }
    }

    func tapCave(_ id: Int) {
        select(.cave(id))
        guard let br = state.breed(inCave: id) else {
            openBreeding(caveId: id)
            return
        }
        let left = br.readyAt.timeIntervalSinceNow
        if left > 0 {
            hud.toast("Egg ready in \(Format.countdown(left)). Use gems to speed up.")
        } else {
            collectCaveEgg(id)
        }
    }

    func openBreeding(caveId: Int) {
        let busy = state.busyDragonIds
        let choices = state.data.dragons.filter { !busy.contains($0.id) }.compactMap { d in
            catalog.species(d.speciesId).map { BreedingPanel.Choice(dragonId: d.id, species: $0) }
        }
        guard choices.count >= 2 else {
            let text = "You need 2 dragons to breed. Hatch another dragon, then tap the cave again."
            let buttons: [Prompts.ButtonSpec] = [
                (title: "Later", color: Palette.muted, action: { [weak self] in self?.closeModal() }),
                (title: "Buy Eggs", color: Palette.accent, action: { [weak self] in self?.openShop(section: .eggs) })
            ]
            presentModal(Prompts.message(title: CaveRules.name, text: text, buttons: buttons, sceneSize: size))
            return
        }
        let cost = catalog.breedingCost
        var blocker: String?
        if state.nurseryFull {
            blocker = "The Nursery is full. Hatch an egg first."
        } else if !state.canAfford(cost) {
            blocker = "Not enough gold (need \(Format.gold(cost)))"
        }
        let panel = BreedingPanel(sceneSize: size, catalog: catalog, choices: choices, cost: cost, blocker: blocker,
                                  outcomes: { [weak self] a, b in self?.state.breedingOutcomes(a, b) ?? [] })
        panel.onConfirm = { [weak self] a, b in self?.startBreeding(caveId: caveId, parentA: a, parentB: b) }
        presentModal(panel)
    }

    func startBreeding(caveId: Int, parentA: Int, parentB: Int) {
        switch state.startBreeding(caveId: caveId, parentA: parentA, parentB: parentB, now: Date()) {
        case .ok:
            closeModal()
            tick()
            if let c = caveNodes[caveId] { Effects.bounce(c) }
            let left = state.remaining(.breeding(caveId), now: Date())
            hud.toast("Breeding started! Egg ready in \(Format.countdown(left))")
            select(.cave(caveId))
            save()
        case .notPossible:
            hud.toast("Those two can't breed together")
        case .busy:
            hud.toast("That cave or dragon is already breeding")
        case .nurseryFull:
            hud.toast("The Nursery is full (\(catalog.nurserySlots) eggs). Hatch one first.")
        case .notEnoughGold:
            hud.toast("Not enough gold")
        }
    }

    func collectCaveEgg(_ caveId: Int) {
        switch state.collectBreeding(caveId: caveId, now: Date()) {
        case .ok(let s):
            tick()
            if let n = nurseryNode { Effects.bounce(n) }
            hud.toast("\(s.name) egg moved to the Nursery!")
            save()
        case .nurseryFull:
            hud.toast("The Nursery is full (\(catalog.nurserySlots) eggs). Hatch one to make room.")
            if let n = nurseryNode { Effects.bounce(n) }
        case .notReady, .nothing:
            refreshInfo()
        }
    }

    func caveInfo(_ id: Int) -> String {
        guard let br = state.breed(inCave: id) else {
            return "\(CaveRules.name) · idle\nTap to breed two dragons (\(Format.gold(catalog.breedingCost)) gold)"
        }
        let names = [br.parentA, br.parentB].compactMap { state.dragon($0) }
            .compactMap { catalog.species($0.speciesId)?.name }.joined(separator: " + ")
        let left = br.readyAt.timeIntervalSinceNow
        return left <= 0
            ? "\(CaveRules.name) · \(names)\nEgg ready! Tap to send it to the Nursery"
            : "\(CaveRules.name) · \(names)\nEgg ready in \(Format.countdown(left))"
    }
}
