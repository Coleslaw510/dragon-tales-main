import SpriteKit

/// Breeding Cave picker: cycle two owned dragons with ◀ ▶, see every possible offspring
/// with its chance, then confirm. Confirm is disabled when the pair can't breed or
/// `blocker` (e.g. nursery full, not enough gold) is set.
final class BreedingPanel: ModalPanel {
    struct Choice {
        let dragonId: Int
        let species: DragonSpecies
    }

    var onConfirm: ((Int, Int) -> Void)?

    private let catalog: Catalog
    private let choices: [Choice]
    private let cost: Int
    private let blocker: String?
    private let outcomesFor: (Int, Int) -> [BreedingOdds.Outcome]
    private var indexA = 0
    private var indexB = 1
    private let dynamic = SKNode()
    private let w: CGFloat
    private let h: CGFloat

    /// `choices` needs at least 2 dragons.
    init(sceneSize: CGSize, catalog: Catalog, choices: [Choice], cost: Int, blocker: String?,
         outcomes: @escaping (Int, Int) -> [BreedingOdds.Outcome]) {
        self.catalog = catalog
        self.choices = choices
        self.cost = cost
        self.blocker = blocker
        outcomesFor = outcomes
        w = min(sceneSize.width - 24, 400)
        h = min(sceneSize.height - 60, 540)
        super.init(title: CaveRules.name, panelSize: CGSize(width: w, height: h), sceneSize: sceneSize)
        closesOnOutsideTap = false
        addContent(dynamic)
        refresh()
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) not used") }

    // MARK: Parent cycling

    private func step(_ which: Int, by delta: Int) {
        guard choices.count >= 2 else { return }
        let n = choices.count
        let other = which == 0 ? indexB : indexA
        var i = which == 0 ? indexA : indexB
        repeat { i = (i + delta + n) % n } while i == other
        if which == 0 { indexA = i } else { indexB = i }
        refresh()
    }

    // MARK: Layout

    private func refresh() {
        dynamic.removeAllChildren()
        let top = h / 2 - 78
        parentRow(0, choice: choices[indexA], y: top)
        let plus = Format.label("+", size: 22)
        plus.position = CGPoint(x: 0, y: top - 36)
        dynamic.addChild(plus)
        parentRow(1, choice: choices[indexB], y: top - 72)

        let outcomes = outcomesFor(choices[indexA].dragonId, choices[indexB].dragonId)
        let header = Format.label("Possible offspring", size: 16, color: Palette.gold)
        header.position = CGPoint(x: 0, y: top - 122)
        dynamic.addChild(header)
        let listTop = top - 152
        if outcomes.isEmpty {
            let none = Format.label("These two can't breed: no 2+ element dragon\nmatches their elements.",
                                    size: 14, bold: false)
            none.numberOfLines = 0
            none.preferredMaxLayoutWidth = w - 40
            none.position = CGPoint(x: 0, y: listTop - 20)
            dynamic.addChild(none)
        } else {
            list(outcomes, top: listTop)
        }

        let footY = -h / 2 + 40
        if let reason = blocker {
            let note = Format.label(reason, size: 13, bold: false, color: SKColor(red: 1, green: 0.6, blue: 0.55, alpha: 1))
            note.position = CGPoint(x: 0, y: footY + 38)
            dynamic.addChild(note)
        }
        let a = choices[indexA].dragonId
        let b = choices[indexB].dragonId
        let confirm = ButtonNode(title: "Breed · \(Format.gold(cost)) gold", size: CGSize(width: w - 60, height: 48),
                                 color: Palette.go, fontSize: 18,
                                 action: { [weak self] in self?.onConfirm?(a, b) })
        confirm.position = CGPoint(x: 0, y: footY)
        confirm.isEnabled = !outcomes.isEmpty && blocker == nil
        dynamic.addChild(confirm)
    }

    private func parentRow(_ which: Int, choice: Choice, y: CGFloat) {
        let left = ButtonNode(title: "◀", size: CGSize(width: 44, height: 44), color: Palette.muted, fontSize: 18,
                              action: { [weak self] in self?.step(which, by: -1) })
        left.position = CGPoint(x: -w / 2 + 36, y: y)
        dynamic.addChild(left)
        let right = ButtonNode(title: "▶", size: CGSize(width: 44, height: 44), color: Palette.muted, fontSize: 18,
                               action: { [weak self] in self?.step(which, by: 1) })
        right.position = CGPoint(x: w / 2 - 36, y: y)
        dynamic.addChild(right)

        let s = choice.species
        let sprite = SKSpriteNode(texture: catalog.dragonTexture(s), size: CGSize(width: 48, height: 48))
        sprite.position = CGPoint(x: -w / 2 + 92, y: y)
        dynamic.addChild(sprite)
        let name = Format.label(s.name, size: 17)
        name.horizontalAlignmentMode = .left
        name.position = CGPoint(x: -w / 2 + 124, y: y + 9)
        dynamic.addChild(name)
        let elements = s.elements.map { catalog.elementName($0) }.joined(separator: " / ")
        let sub = Format.label("\(elements) · \(s.rarity)", size: 12, bold: false, color: catalog.rarityColor(s.rarity))
        sub.horizontalAlignmentMode = .left
        sub.position = CGPoint(x: -w / 2 + 124, y: y - 11)
        dynamic.addChild(sub)
    }

    /// One column for up to 6 outcomes, two columns beyond that.
    private func list(_ outcomes: [BreedingOdds.Outcome], top: CGFloat) {
        let columns = outcomes.count > 6 ? 2 : 1
        let perColumn = Int((Double(outcomes.count) / Double(columns)).rounded(.up))
        let colW = (w - 30) / CGFloat(columns)
        let rowH: CGFloat = 30
        for (i, o) in outcomes.enumerated() {
            let col = i / perColumn
            let row = i % perColumn
            let x0 = -w / 2 + 15 + CGFloat(col) * colW
            let y = top - CGFloat(row) * rowH
            let icon = SKSpriteNode(texture: catalog.dragonTexture(o.species), size: CGSize(width: 26, height: 26))
            icon.position = CGPoint(x: x0 + 14, y: y)
            dynamic.addChild(icon)
            let name = Format.label(o.species.name, size: columns == 1 ? 15 : 13,
                                    color: catalog.rarityColor(o.species.rarity))
            name.horizontalAlignmentMode = .left
            name.position = CGPoint(x: x0 + 32, y: y)
            dynamic.addChild(name)
            let pct = Format.label(o.percentText, size: columns == 1 ? 15 : 13)
            pct.horizontalAlignmentMode = .right
            pct.position = CGPoint(x: x0 + colW - 8, y: y)
            dynamic.addChild(pct)
        }
    }
}
