import Foundation

/// Breeding Cave tuning that isn't odds (odds and timers are in BreedingOdds.swift).
enum CaveRules {
    static let name = "Breeding Cave"
    /// Shop price of one Breeding Cave, in gold.
    static let cost = 400
}

/// Park rules for Breeding Caves: place, start a breed, timers, and moving the egg to the nursery.
extension GameState {
    var caves: [BuildingSave] { data.buildings.filter { $0.kind == .cave } }

    /// The breed running (or waiting to be collected) in a cave.
    func breed(inCave id: Int) -> BreedSave? {
        data.breeding?.first(where: { $0.caveId == id })
    }

    /// Dragons currently parenting a breed (can't be picked again until it finishes).
    var busyDragonIds: Set<Int> {
        Set((data.breeding ?? []).flatMap { [$0.parentA, $0.parentB] })
    }

    func breedingOutcomes(_ a: Int, _ b: Int) -> [BreedingOdds.Outcome] {
        guard a != b, let da = dragon(a), let db = dragon(b),
              let sa = catalog.species(da.speciesId), let sb = catalog.species(db.speciesId) else { return [] }
        return BreedingOdds.outcomes(sa, sb, pool: catalog.species)
    }

    /// Charges the cave cost and places it. Returns nil if gold ran out.
    func placeCave(col: Int, row: Int, now: Date) -> BuildingSave? {
        guard spend(CaveRules.cost) else { return nil }
        let b = BuildingSave(id: makeId(), kind: .cave, element: nil,
                             col: col, row: row, storedGold: 0, lastAccrual: now)
        data.buildings.append(b)
        return b
    }

    enum BreedStartResult {
        case ok(DragonSpecies)
        case notPossible
        case busy
        case nurseryFull
        case notEnoughGold
    }

    /// Rolls the offspring now; its rarity sets the timer.
    func startBreeding(caveId: Int, parentA: Int, parentB: Int, now: Date) -> BreedStartResult {
        guard building(caveId)?.kind == .cave, breed(inCave: caveId) == nil else { return .busy }
        let busy = busyDragonIds
        guard !busy.contains(parentA), !busy.contains(parentB) else { return .busy }
        guard let result = BreedingOdds.roll(breedingOutcomes(parentA, parentB)) else { return .notPossible }
        if nurseryFull { return .nurseryFull }
        guard spend(catalog.breedingCost) else { return .notEnoughGold }
        let ready = now.addingTimeInterval(BreedingOdds.breedSeconds(result))
        let br = BreedSave(id: makeId(), caveId: caveId, parentA: parentA, parentB: parentB,
                           speciesId: result.id, startedAt: now, readyAt: ready)
        data.breeding = (data.breeding ?? []) + [br]
        return .ok(result)
    }

    enum BreedCollectResult {
        case ok(DragonSpecies)
        case notReady
        case nurseryFull
        case nothing
    }

    /// Moves a finished breed's egg into the nursery (blocked while the nursery is full).
    func collectBreeding(caveId: Int, now: Date) -> BreedCollectResult {
        guard let br = breed(inCave: caveId), let s = catalog.species(br.speciesId) else { return .nothing }
        guard br.readyAt <= now else { return .notReady }
        if nurseryFull { return .nurseryFull }
        data.breeding?.removeAll(where: { $0.id == br.id })
        let ready = now.addingTimeInterval(catalog.incubationSeconds(s))
        data.eggs.append(EggSave(id: makeId(), speciesId: s.id, startedAt: now, readyAt: ready))
        return .ok(s)
    }
}
