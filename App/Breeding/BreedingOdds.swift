import Foundation

/// Breeding odds: which species two parents can produce and how likely each one is.
/// All tuning numbers live here as constants; everything else reads them.
///
/// Rules:
/// - Parents with one shared element (e.g. fire + fire) always give that element's base dragon.
/// - Otherwise the pool is every species whose elements are a subset of the parents' combined
///   elements AND that has at least `minMixedElements` elements. A mixed pairing never gives a
///   single-element dragon; if the pool is empty the pair can't breed.
/// - Each species in the pool is weighted by its rarity (`rarityWeights`), then rolled randomly.
enum BreedingOdds {
    // MARK: Tuning

    /// Relative chance per result rarity. Keep common > rare > epic > legendary.
    static let rarityWeights: [String: Double] = [
        "common": 50,
        "rare": 28,
        "epic": 14,
        "legendary": 6
    ]
    /// Weight for any rarity missing from `rarityWeights`.
    static let fallbackWeight: Double = 1

    /// Breeding timer by result rarity, in seconds.
    static let breedSecondsByRarity: [String: Double] = [
        "common": 60,          // 1 min
        "rare": 10 * 60,       // 10 min
        "epic": 45 * 60,       // 45 min
        "legendary": 3 * 3600  // 3 h
    ]
    /// Timer for any rarity missing from `breedSecondsByRarity`.
    static let fallbackBreedSeconds: Double = 10 * 60

    /// Minimum element count for an offspring of a mixed-element pairing.
    static let minMixedElements = 2

    // MARK: Odds

    struct Outcome {
        let species: DragonSpecies
        /// 0...1; all outcomes of one pairing sum to 1.
        let chance: Double

        var percentText: String { BreedingOdds.percentText(chance) }
    }

    static func weight(_ rarity: String) -> Double {
        rarityWeights[rarity] ?? fallbackWeight
    }

    static func breedSeconds(_ s: DragonSpecies) -> Double {
        breedSecondsByRarity[s.rarity] ?? fallbackBreedSeconds
    }

    /// Every possible offspring of `a` x `b` with its chance, most likely first.
    /// Empty when the pair can't breed.
    static func outcomes(_ a: DragonSpecies, _ b: DragonSpecies, pool: [DragonSpecies]) -> [Outcome] {
        let combined = Set(a.elements).union(b.elements)
        if combined.count == 1, let element = combined.first {
            // Same single element: always that element's base dragon.
            guard let base = pool.first(where: { $0.isBase && $0.element == element }) else { return [] }
            return [Outcome(species: base, chance: 1)]
        }
        let eligible = pool.filter { s in
            s.elements.count >= minMixedElements && Set(s.elements).isSubset(of: combined)
        }
        let total = eligible.reduce(0) { $0 + weight($1.rarity) }
        guard total > 0 else { return [] }
        return eligible
            .map { Outcome(species: $0, chance: weight($0.rarity) / total) }
            .sorted { $0.chance != $1.chance ? $0.chance > $1.chance : $0.species.name < $1.species.name }
    }

    /// Random pick by chance, so repeated breeds of the same pair vary.
    static func roll(_ outcomes: [Outcome]) -> DragonSpecies? {
        var rng = SystemRandomNumberGenerator()
        return roll(outcomes, using: &rng)
    }

    static func roll<R: RandomNumberGenerator>(_ outcomes: [Outcome], using rng: inout R) -> DragonSpecies? {
        guard !outcomes.isEmpty else { return nil }
        let total = outcomes.reduce(0) { $0 + $1.chance }
        var pick = Double.random(in: 0..<max(total, .leastNonzeroMagnitude), using: &rng)
        for o in outcomes {
            pick -= o.chance
            if pick < 0 { return o.species }
        }
        return outcomes.last?.species
    }

    /// "100%", "35.7%", "<0.1%".
    static func percentText(_ chance: Double) -> String {
        let p = chance * 100
        if p >= 99.95 { return "100%" }
        if p < 0.1 { return "<0.1%" }
        return String(format: "%.1f%%", p)
    }
}
