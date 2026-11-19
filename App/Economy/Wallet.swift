import Foundation

/// Gold balance and habitat income: each dragon earns incomePerMinute * 60 gold/hour,
/// stored in its habitat up to `storageCap`. Offline time is capped at `maxOfflineSeconds`.
extension GameState {
    var gold: Int { data.gold }

    func canAfford(_ cost: Int) -> Bool { data.gold >= cost }

    @discardableResult
    func spend(_ cost: Int) -> Bool {
        guard canAfford(cost) else { return false }
        data.gold -= cost
        return true
    }

    func earn(_ amount: Int) {
        data.gold += max(0, amount)
    }

    func goldPerHour(habitatId: Int) -> Double {
        dragons(inHabitat: habitatId).reduce(0.0) { sum, d in
            sum + goldPerHour(dragon: d)
        }
    }

    func goldPerHour(dragon d: DragonSave) -> Double {
        guard let s = catalog.species(d.speciesId) else { return 0 }
        return catalog.goldPerHour(s)
    }

    func storedGold(habitatId: Int) -> Int {
        Int((building(habitatId)?.storedGold ?? 0).rounded(.down))
    }

    func accrueAll(now: Date) {
        for i in data.buildings.indices { accrue(index: i, now: now) }
    }

    func accrue(habitatId: Int, now: Date) {
        guard let i = data.buildings.firstIndex(where: { $0.id == habitatId }) else { return }
        accrue(index: i, now: now)
    }

    private func accrue(index i: Int, now: Date) {
        var b = data.buildings[i]
        guard b.kind == .habitat else { return }
        let elapsed = min(max(0, now.timeIntervalSince(b.lastAccrual)), catalog.maxOfflineSeconds)
        let rate = goldPerHour(habitatId: b.id)
        b.storedGold = min(catalog.habitatStorageCap, b.storedGold + rate * elapsed / 3600)
        b.lastAccrual = now
        data.buildings[i] = b
    }

    /// Moves whole coins from the habitat into the wallet. Returns the amount collected.
    func collect(habitatId: Int, now: Date) -> Int {
        accrue(habitatId: habitatId, now: now)
        guard let i = data.buildings.firstIndex(where: { $0.id == habitatId }) else { return 0 }
        let amount = Int(data.buildings[i].storedGold.rounded(.down))
        guard amount > 0 else { return 0 }
        data.buildings[i].storedGold -= Double(amount)
        earn(amount)
        return amount
    }
}
