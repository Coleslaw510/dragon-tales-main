import Foundation

// MARK: - Catalog (decoded from Data/*.json)

struct DragonSpecies: Codable {
    let id: String
    let name: String
    let elements: [String]
    let rarity: String
    let kind: String
    let sprite: String
    let blurb: String?
    let incubateSeconds: Double?
    let incomePerMinute: Double?

    /// Base = one element, sold in the shop.
    var isBase: Bool { kind == "base" && elements.count == 1 }
    var element: String { elements.first ?? "fire" }
}

struct DragonFile: Codable {
    let dragons: [DragonSpecies]
}

struct ElementInfo: Codable {
    let id: String
    let name: String
    let color: String?
    let egg: String?
    let habitat: String?
}

struct LayoutEntry: Codable {
    let kind: String
    let col: Int
    let row: Int
    let element: String?
}

struct Economy: Codable {
    struct Starting: Codable {
        let coins: Double?
        let layout: [LayoutEntry]?
    }
    struct Shop: Codable {
        let baseEggCost: Int
        let habitatCost: Int
    }
    struct Habitats: Codable {
        let capacity: Int
        let coinsPerMinute: Double?
        let storageCap: Double
        let maxOfflineSeconds: Double?
    }
    struct Hatchery: Codable {
        let slots: Int
        let secondsByRarity: [String: Double]
    }
    struct Plot: Codable {
        let id: String
        let minCol: Int
        let maxCol: Int
        let minRow: Int
        let maxRow: Int
        let startsUnlocked: Bool?
    }
    struct Island: Codable {
        let cell: Double
        let minZoom: Double
        let maxZoom: Double
        let plots: [Plot]
    }
    struct BuildingInfo: Codable {
        let name: String
        let sprite: String
    }

    let starting: Starting?
    let elements: [ElementInfo]
    let shop: Shop
    let habitats: Habitats
    let hatchery: Hatchery
    let island: Island
    let buildings: [String: BuildingInfo]?
}

// MARK: - Save (persisted park state)

enum BuildingKind: String, Codable {
    case nursery
    case habitat
}

struct BuildingSave: Codable {
    var id: Int
    var kind: BuildingKind
    var element: String?
    var col: Int
    var row: Int
    var storedGold: Double
    var lastAccrual: Date
}

struct EggSave: Codable {
    var id: Int
    var speciesId: String
    var startedAt: Date
    var readyAt: Date
}

struct DragonSave: Codable {
    var id: Int
    var speciesId: String
    var habitatId: Int
    var hatchedAt: Date
}

struct SaveData: Codable {
    var version: Int
    var gold: Int
    var nextId: Int
    var buildings: [BuildingSave]
    var eggs: [EggSave]
    var dragons: [DragonSave]
    var savedAt: Date
}
