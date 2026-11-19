import Foundation
import SpriteKit
import UIKit

/// Loads Data/*.json and Art/ textures from the bundle (both are folder references).
final class Catalog {
    static let shared = Catalog()

    let economy: Economy
    let species: [DragonSpecies]
    private let speciesById: [String: DragonSpecies]
    private var textures: [String: SKTexture] = [:]

    private init() {
        guard let eco = Catalog.decode(Economy.self, file: "economy") else {
            fatalError("Data/economy.json missing or invalid")
        }
        economy = eco
        let list = Catalog.decode(DragonFile.self, file: "dragons")?.dragons ?? []
        species = list
        var map: [String: DragonSpecies] = [:]
        for s in list { map[s.id] = s }
        speciesById = map
    }

    private static func decode<T: Decodable>(_ type: T.Type, file: String) -> T? {
        guard let url = Bundle.main.url(forResource: file, withExtension: "json", subdirectory: "Data"),
              let data = try? Data(contentsOf: url) else {
            print("Catalog: missing Data/\(file).json")
            return nil
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("Catalog: failed to decode \(file).json: \(error)")
            return nil
        }
    }

    // MARK: Species and elements

    func species(_ id: String) -> DragonSpecies? { speciesById[id] }

    /// Base single-element dragons, in economy.json element order.
    var baseSpecies: [DragonSpecies] {
        let order = economy.elements.map { $0.id }
        return species.filter { $0.isBase }.sorted { a, b in
            (order.firstIndex(of: a.element) ?? 99) < (order.firstIndex(of: b.element) ?? 99)
        }
    }

    func elementInfo(_ id: String) -> ElementInfo? {
        economy.elements.first(where: { $0.id == id })
    }

    func elementName(_ id: String) -> String {
        elementInfo(id)?.name ?? id.capitalized
    }

    func elementColor(_ id: String) -> SKColor {
        SKColor(hex: elementInfo(id)?.color ?? "#8899AA")
    }

    // MARK: Economy numbers

    var eggCost: Int { economy.shop.baseEggCost }
    var habitatCost: Int { economy.shop.habitatCost }
    var habitatCapacity: Int { economy.habitats.capacity }
    var storageHours: Double { economy.habitats.storageHours ?? 4 }
    var maxOfflineSeconds: Double { economy.habitats.maxOfflineSeconds ?? 43200 }
    var nurserySlots: Int { max(1, economy.hatchery.slots) }
    var startingGems: Int { economy.starting?.gems ?? 20 }
    var secondsPerGem: Double { max(1, economy.gems?.secondsPerGem ?? 90) }
    var minimumSkipCost: Int { economy.gems?.minimumSkipCost ?? 1 }
    var breedingCost: Int { economy.breeding?.costCoins ?? 120 }

    func rarityColor(_ rarity: String) -> SKColor {
        SKColor(hex: economy.rarities?[rarity]?.color ?? "#8899AA")
    }

    /// Milestone 1 start: exactly one habitat + one egg.
    var startingGold: Int { habitatCost + eggCost }

    func incubationSeconds(_ s: DragonSpecies) -> Double {
        if let v = s.incubateSeconds, v > 0 { return v }
        return economy.hatchery.secondsByRarity[s.rarity] ?? 120
    }

    func goldPerHour(_ s: DragonSpecies) -> Double {
        (s.incomePerMinute ?? economy.habitats.coinsPerMinute ?? 12) * 60
    }

    // MARK: Textures (Art/ only)

    func texture(_ path: String) -> SKTexture {
        if let cached = textures[path] { return cached }
        var tex = SKTexture()
        if let base = Bundle.main.resourceURL {
            let file = base.appendingPathComponent("Art").appendingPathComponent(path).path
            if let image = UIImage(contentsOfFile: file) {
                tex = SKTexture(image: image)
            } else {
                print("Catalog: missing Art/\(path)")
            }
        }
        textures[path] = tex
        return tex
    }

    func habitatTexture(_ element: String) -> SKTexture {
        let file = elementInfo(element)?.habitat ?? "habitat_\(element).png"
        return texture("habitats/" + file)
    }

    func dragonTexture(_ s: DragonSpecies) -> SKTexture {
        texture("dragons/" + s.sprite)
    }

    func eggTexture(_ s: DragonSpecies) -> SKTexture {
        switch s.rarity {
        case "legendary":
            return texture("dragons/egg_legendary.png")
        case "rare", "epic":
            return texture("dragons/egg_rare.png")
        default:
            let file = elementInfo(s.element)?.egg ?? "egg_\(s.element).png"
            return texture("dragons/" + file)
        }
    }

    /// Breeding Cave reuses the shipped grove art.
    var caveTexture: SKTexture {
        let file = economy.buildings?["grove"]?.sprite ?? "building_grove.png"
        return texture("buildings/" + file)
    }

    var nurseryTexture: SKTexture {
        let file = economy.buildings?["hatchery"]?.sprite ?? "building_hatchery.png"
        return texture("buildings/" + file)
    }

    var coinTexture: SKTexture { texture("ui/icon_coin.png") }
    var gemTexture: SKTexture { texture("ui/icon_gem.png") }

    func buildingTexture(_ file: String) -> SKTexture { texture("buildings/" + file) }
}

extension SKColor {
    convenience init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        let v = UInt64(s, radix: 16) ?? 0x8899AA
        self.init(red: CGFloat((v >> 16) & 0xFF) / 255,
                  green: CGFloat((v >> 8) & 0xFF) / 255,
                  blue: CGFloat(v & 0xFF) / 255,
                  alpha: 1)
    }
}
