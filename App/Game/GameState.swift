import Foundation

/// Mutable park state plus the rules for eggs, habitats, and hatching.
/// Gold and income live in Economy/Wallet.swift.
final class GameState {
    var data: SaveData
    let catalog: Catalog

    init(data: SaveData, catalog: Catalog) {
        self.data = data
        self.catalog = catalog
    }

    func makeId() -> Int {
        let id = data.nextId
        data.nextId += 1
        return id
    }

    // MARK: Queries

    var habitats: [BuildingSave] { data.buildings.filter { $0.kind == .habitat } }

    func building(_ id: Int) -> BuildingSave? { data.buildings.first(where: { $0.id == id }) }
    func egg(_ id: Int) -> EggSave? { data.eggs.first(where: { $0.id == id }) }
    func dragon(_ id: Int) -> DragonSave? { data.dragons.first(where: { $0.id == id }) }

    func dragons(inHabitat id: Int) -> [DragonSave] {
        data.dragons.filter { $0.habitatId == id }
    }

    func freeSpace(habitatId: Int) -> Int {
        max(0, catalog.habitatCapacity - dragons(inHabitat: habitatId).count)
    }

    /// Habitats matching one of the species' elements that still have room.
    func compatibleHabitats(for s: DragonSpecies) -> [BuildingSave] {
        habitats.filter { b in
            s.elements.contains(b.element ?? "") && freeSpace(habitatId: b.id) > 0
        }
    }

    var nurseryFull: Bool { data.eggs.count >= catalog.nurserySlots }

    func occupiedCells(grid: IslandGrid) -> Set<GridCell> {
        var cells = Set<GridCell>()
        for b in data.buildings {
            for c in grid.footprint(col: b.col, row: b.row) { cells.insert(c) }
        }
        return cells
    }

    // MARK: Actions

    enum BuyResult {
        case ok
        case notEnoughGold
        case nurseryFull
    }

    func buyEgg(_ s: DragonSpecies, now: Date) -> BuyResult {
        if nurseryFull { return .nurseryFull }
        guard spend(catalog.eggCost) else { return .notEnoughGold }
        let ready = now.addingTimeInterval(catalog.incubationSeconds(s))
        data.eggs.append(EggSave(id: makeId(), speciesId: s.id, startedAt: now, readyAt: ready))
        return .ok
    }

    /// Charges the habitat cost and places it. Returns nil if gold ran out.
    func placeHabitat(element: String, col: Int, row: Int, now: Date) -> BuildingSave? {
        guard spend(catalog.habitatCost) else { return nil }
        let b = BuildingSave(id: makeId(), kind: .habitat, element: element,
                             col: col, row: row, storedGold: 0, lastAccrual: now)
        data.buildings.append(b)
        return b
    }

    /// Moves a ready egg into a compatible habitat with space.
    func hatch(eggId: Int, habitatId: Int, now: Date) -> DragonSave? {
        guard let i = data.eggs.firstIndex(where: { $0.id == eggId }),
              data.eggs[i].readyAt <= now,
              let s = catalog.species(data.eggs[i].speciesId),
              let hab = building(habitatId),
              s.elements.contains(hab.element ?? ""),
              freeSpace(habitatId: habitatId) > 0 else { return nil }
        accrue(habitatId: habitatId, now: now)
        data.eggs.remove(at: i)
        let d = DragonSave(id: makeId(), speciesId: s.id, habitatId: habitatId, hatchedAt: now)
        data.dragons.append(d)
        return d
    }
}
