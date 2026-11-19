import SpriteKit

/// Shop with two tabs: Eggs (base single-element dragons) and Habitats (one per element).
/// Prices come from economy.json `shop`.
final class ShopOverlay: ModalPanel {
    enum Tab {
        case eggs
        case habitats
    }

    private struct Item {
        let title: String
        let subtitle: String
        let price: Int
        let texture: SKTexture
        let color: SKColor
        let buy: () -> Void
    }

    var onBuyEgg: ((DragonSpecies) -> Void)?
    var onBuyHabitat: ((String) -> Void)?

    private let catalog: Catalog
    private let gold: Int
    private let content = SKNode()
    private var eggTab: ButtonNode?
    private var habitatTab: ButtonNode?

    init(sceneSize: CGSize, catalog: Catalog, gold: Int, tab: Tab) {
        self.catalog = catalog
        self.gold = gold
        let w = min(sceneSize.width - 24, 440)
        let h = min(sceneSize.height - 140, 700)
        super.init(title: "Shop", panelSize: CGSize(width: w, height: h), sceneSize: sceneSize)

        let tabW = (w - 50) / 2
        let tabY = h / 2 - 86
        let eggs = ButtonNode(title: "Eggs", size: CGSize(width: tabW, height: 42), color: Palette.muted)
        eggs.position = CGPoint(x: -tabW / 2 - 5, y: tabY)
        eggs.action = { [weak self] in self?.show(.eggs) }
        let habitats = ButtonNode(title: "Habitats", size: CGSize(width: tabW, height: 42), color: Palette.muted)
        habitats.position = CGPoint(x: tabW / 2 + 5, y: tabY)
        habitats.action = { [weak self] in self?.show(.habitats) }
        eggTab = eggs
        habitatTab = habitats
        addContent(eggs)
        addContent(habitats)
        addContent(content)
        show(tab)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) not used") }

    private func show(_ tab: Tab) {
        eggTab?.setFill(tab == .eggs ? Palette.accent : Palette.muted)
        habitatTab?.setFill(tab == .habitats ? Palette.accent : Palette.muted)
        content.removeAllChildren()
        let items = tab == .eggs ? eggItems() : habitatItems()
        let cols = 2
        let gap: CGFloat = 10
        let rows = max(1, (items.count + cols - 1) / cols)
        let areaTop = panelSize.height / 2 - 120
        let areaBottom = -panelSize.height / 2 + 16
        let cellW = (panelSize.width - 30 - gap) / 2
        let cellH = min(120, (areaTop - areaBottom - gap * CGFloat(rows - 1)) / CGFloat(rows))
        for (i, item) in items.enumerated() {
            let c = i % cols
            let r = i / cols
            let cell = makeCell(item, size: CGSize(width: cellW, height: cellH))
            cell.position = CGPoint(x: -panelSize.width / 2 + 15 + cellW / 2 + CGFloat(c) * (cellW + gap),
                                    y: areaTop - cellH / 2 - CGFloat(r) * (cellH + gap))
            content.addChild(cell)
        }
    }

    private func eggItems() -> [Item] {
        catalog.baseSpecies.map { s -> Item in
            Item(title: s.name, subtitle: catalog.elementName(s.element) + " egg",
                 price: catalog.eggCost, texture: catalog.eggTexture(s),
                 color: catalog.elementColor(s.element),
                 buy: { [weak self] in self?.onBuyEgg?(s) })
        }
    }

    private func habitatItems() -> [Item] {
        catalog.economy.elements.map { e -> Item in
            let id = e.id
            return Item(title: "\(e.name) Habitat", subtitle: "Holds \(catalog.habitatCapacity)",
                        price: catalog.habitatCost, texture: catalog.habitatTexture(id),
                        color: catalog.elementColor(id),
                        buy: { [weak self] in self?.onBuyHabitat?(id) })
        }
    }

    private func makeCell(_ item: Item, size: CGSize) -> ButtonNode {
        let cell = ButtonNode(title: "", size: size, color: item.color.withAlphaComponent(0.4), fontSize: 1)
        cell.action = item.buy
        let iconSide = size.height * 0.48
        let icon = SKSpriteNode(texture: item.texture, size: CGSize(width: iconSide, height: iconSide))
        icon.position = CGPoint(x: 0, y: size.height / 2 - iconSide / 2 - 4)
        icon.zPosition = 3
        cell.addChild(icon)

        let name = Format.label(item.title, size: min(16, size.height * 0.15))
        name.position = CGPoint(x: 0, y: -size.height * 0.08)
        name.zPosition = 3
        cell.addChild(name)

        let sub = Format.label(item.subtitle, size: min(12, size.height * 0.11), bold: false)
        sub.position = CGPoint(x: 0, y: -size.height * 0.22)
        sub.zPosition = 3
        cell.addChild(sub)

        let priceY = -size.height / 2 + size.height * 0.12
        let coin = SKSpriteNode(texture: catalog.coinTexture, size: CGSize(width: 18, height: 18))
        coin.position = CGPoint(x: -24, y: priceY)
        coin.zPosition = 3
        cell.addChild(coin)
        let affordable = gold >= item.price
        let price = Format.label(Format.gold(item.price), size: 15,
                                 color: affordable ? Palette.gold : SKColor(red: 1, green: 0.45, blue: 0.42, alpha: 1))
        price.horizontalAlignmentMode = .left
        price.position = CGPoint(x: -12, y: priceY)
        price.zPosition = 3
        cell.addChild(price)
        return cell
    }
}
