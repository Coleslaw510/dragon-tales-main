import Foundation

/// Codable save file in Documents. Timestamps in the save let timers and income
/// keep running while the app is closed.
enum SaveStore {
    static var url: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("dragontales_save.json")
    }

    static func load() -> SaveData? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        do {
            return try JSONDecoder().decode(SaveData.self, from: data)
        } catch {
            print("SaveStore: could not read save: \(error)")
            return nil
        }
    }

    static func save(_ state: SaveData) {
        var copy = state
        copy.savedAt = Date()
        do {
            let data = try JSONEncoder().encode(copy)
            try data.write(to: url, options: .atomic)
        } catch {
            print("SaveStore: could not write save: \(error)")
        }
    }

    /// Fresh park: the nursery at the starting hatchery spot, gold for one habitat + one egg,
    /// and a few starting gems.
    static func newGame(catalog: Catalog, grid: IslandGrid, now: Date) -> SaveData {
        let spot = catalog.economy.starting?.layout?.first(where: { $0.kind == "hatchery" })
        var col = spot?.col ?? -2
        var row = spot?.row ?? 2
        if !grid.canPlace(col: col, row: row, occupied: []),
           let alt = grid.nearestFree(to: .zero, occupied: []) {
            col = alt.col
            row = alt.row
        }
        let nursery = BuildingSave(id: 1, kind: .nursery, element: nil, col: col, row: row,
                                   storedGold: 0, lastAccrual: now)
        return SaveData(version: 2, gold: catalog.startingGold, gems: catalog.startingGems,
                        discovered: [], nextId: 2,
                        buildings: [nursery], eggs: [], dragons: [], savedAt: now)
    }
}
