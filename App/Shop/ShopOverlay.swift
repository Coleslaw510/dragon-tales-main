import SpriteKit

/// Dragon City-style shop: a menu of large section buttons (Eggs, Habitats, Buildings);
/// tapping one opens that section's grid, with a Back button to the menu.
/// Items and cells are in ShopItems.swift; prices come from economy.json `shop`.
final class ShopOverlay: ModalPanel {
    enum Section: CaseIterable {
        case eggs
        case habitats
        case buildings

        var title: String {
            switch self {
            case .eggs: return "Eggs"
            case .habitats: return "Habitats"
            case .buildings: return "Buildings"
            }
        }

        var subtitle: String {
            switch self {
            case .eggs: return "Hatch new dragons"
            case .habitats: return "Homes that earn gold"
            case .buildings: return "Nursery, grove & decor"
            }
        }
    }

    struct Item {
        let title: String
        let subtitle: String
        let price: Int
        let texture: SKTexture
        let color: SKColor
        /// When set, shown instead of the price and the item can't be bought.
        let note: String?
        let buy: () -> Void
    }

    var onBuyEgg: ((DragonSpecies) -> Void)?
    var onBuyHabitat: ((String) -> Void)?
    var onUnavailable: ((String) -> Void)?

    let catalog: Catalog
    let gold: Int
    private let content = SKNode()

    init(sceneSize: CGSize, catalog: Catalog, gold: Int, section: Section?) {
        self.catalog = catalog
        self.gold = gold
        let w = min(sceneSize.width - 24, 440)
        let h = min(sceneSize.height - 140, 700)
        super.init(title: "Shop", panelSize: CGSize(width: w, height: h), sceneSize: sceneSize)
        addContent(content)
        if let section = section { show(section) } else { showMenu() }
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) not used") }

    // MARK: Menu

    func showMenu() {
        content.removeAllChildren()
        let w = panelSize.width - 40
        let top = panelSize.height / 2 - 76
        let bottom = -panelSize.height / 2 + 20
        let gap: CGFloat = 16
        let count = CGFloat(Section.allCases.count)
        let bh = min(150, (top - bottom - gap * (count - 1)) / count)
        for (i, section) in Section.allCases.enumerated() {
            let b = menuButton(section, size: CGSize(width: w, height: bh))
            b.position = CGPoint(x: 0, y: top - bh / 2 - CGFloat(i) * (bh + gap))
            content.addChild(b)
        }
    }

    private func menuButton(_ section: Section, size: CGSize) -> ButtonNode {
        let b = ButtonNode(title: "", size: size, color: color(section), fontSize: 1)
        b.action = { [weak self] in self?.show(section) }
        let side = size.height * 0.78
        let icon = SKSpriteNode(texture: icon(section), size: CGSize(width: side, height: side))
        icon.position = CGPoint(x: -size.width / 2 + 16 + side / 2, y: 0)
        icon.zPosition = 3
        b.addChild(icon)
        let textX = icon.position.x + side / 2 + 16
        let title = Format.label(section.title, size: min(30, size.height * 0.26))
        title.fontName = "AvenirNext-Heavy"
        title.horizontalAlignmentMode = .left
        title.position = CGPoint(x: textX, y: size.height * 0.12)
        title.zPosition = 3
        b.addChild(title)
        let sub = Format.label(section.subtitle, size: min(16, size.height * 0.14), bold: false)
        sub.horizontalAlignmentMode = .left
        sub.position = CGPoint(x: textX, y: -size.height * 0.18)
        sub.zPosition = 3
        b.addChild(sub)
        let chevron = Format.label("›", size: 40)
        chevron.position = CGPoint(x: size.width / 2 - 24, y: 0)
        chevron.zPosition = 3
        b.addChild(chevron)
        return b
    }

    private func color(_ s: Section) -> SKColor {
        switch s {
        case .eggs: return Palette.accent
        case .habitats: return Palette.go
        case .buildings: return SKColor(red: 0.25, green: 0.48, blue: 0.85, alpha: 1)
        }
    }

    private func icon(_ s: Section) -> SKTexture {
        switch s {
        case .eggs: return catalog.texture("dragons/egg_fire.png")
        case .habitats: return catalog.habitatTexture("plant")
        case .buildings: return catalog.nurseryTexture
        }
    }

    // MARK: Section grid

    func show(_ section: Section) {
        content.removeAllChildren()
        let headerY = panelSize.height / 2 - 82
        let back = ButtonNode(title: "‹ Back", size: CGSize(width: 96, height: 40), color: Palette.muted, fontSize: 17)
        back.position = CGPoint(x: -panelSize.width / 2 + 15 + 48, y: headerY)
        back.action = { [weak self] in self?.showMenu() }
        content.addChild(back)
        let header = Format.label(section.title, size: 22, color: Palette.gold)
        header.position = CGPoint(x: 30, y: headerY)
        content.addChild(header)

        let items = self.items(section)
        let cols = 2
        let gap: CGFloat = 10
        let rows = max(1, (items.count + cols - 1) / cols)
        let areaTop = panelSize.height / 2 - 112
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

    private func items(_ section: Section) -> [Item] {
        switch section {
        case .eggs: return eggItems()
        case .habitats: return habitatItems()
        case .buildings: return buildingItems()
        }
    }
}
