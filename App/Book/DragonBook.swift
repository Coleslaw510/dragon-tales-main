import SpriteKit

/// Dragon Book: every species in dragons.json, paged in a grid. Discovered (ever hatched)
/// dragons show full art; the rest show a filled silhouette of their art with name and elements.
final class DragonBook: ModalPanel {
    static let cols = 4
    static let rows = 5

    private let catalog: Catalog
    private let discovered: Set<String>
    private let content = SKNode()
    private let pageLabel = Format.label("", size: 15)
    private var page = 0
    private var pageCount: Int {
        max(1, (catalog.species.count + DragonBook.perPage - 1) / DragonBook.perPage)
    }
    private static var perPage: Int { cols * rows }

    init(sceneSize: CGSize, catalog: Catalog, discovered: Set<String>) {
        self.catalog = catalog
        self.discovered = discovered
        let w = min(sceneSize.width - 24, 440)
        let h = min(sceneSize.height - 140, 700)
        super.init(title: "Dragon Book", panelSize: CGSize(width: w, height: h), sceneSize: sceneSize)

        let owned = catalog.species.filter { discovered.contains($0.id) }.count
        let count = Format.label("Discovered \(owned) / \(catalog.species.count)", size: 15,
                                 bold: false, color: Palette.gold)
        count.position = CGPoint(x: 0, y: h / 2 - 68)
        addContent(count)

        let navY = -h / 2 + 30
        let prev = ButtonNode(title: "‹", size: CGSize(width: 64, height: 40), color: Palette.muted, fontSize: 26)
        prev.position = CGPoint(x: -w / 2 + 50, y: navY)
        prev.action = { [weak self] in self?.turn(-1) }
        let next = ButtonNode(title: "›", size: CGSize(width: 64, height: 40), color: Palette.muted, fontSize: 26)
        next.position = CGPoint(x: w / 2 - 50, y: navY)
        next.action = { [weak self] in self?.turn(1) }
        pageLabel.position = CGPoint(x: 0, y: navY)
        addContent(prev)
        addContent(next)
        addContent(pageLabel)
        addContent(content)
        showPage()
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) not used") }

    private func turn(_ delta: Int) {
        page = (page + delta + pageCount) % pageCount
        showPage()
    }

    private func showPage() {
        content.removeAllChildren()
        pageLabel.text = "Page \(page + 1) / \(pageCount)"
        let gap: CGFloat = 6
        let top = panelSize.height / 2 - 86
        let bottom = -panelSize.height / 2 + 58
        let cellW = (panelSize.width - 24 - gap * CGFloat(DragonBook.cols - 1)) / CGFloat(DragonBook.cols)
        let cellH = (top - bottom - gap * CGFloat(DragonBook.rows - 1)) / CGFloat(DragonBook.rows)
        let start = page * DragonBook.perPage
        let slice = catalog.species.dropFirst(start).prefix(DragonBook.perPage)
        for (i, s) in slice.enumerated() {
            let c = i % DragonBook.cols
            let r = i / DragonBook.cols
            let cell = makeCell(s, size: CGSize(width: cellW, height: cellH))
            cell.position = CGPoint(x: -panelSize.width / 2 + 12 + cellW / 2 + CGFloat(c) * (cellW + gap),
                                    y: top - cellH / 2 - CGFloat(r) * (cellH + gap))
            content.addChild(cell)
        }
    }

    private func makeCell(_ s: DragonSpecies, size: CGSize) -> SKNode {
        let owned = discovered.contains(s.id)
        let cell = SKNode()
        let bg = SKShapeNode(rectOf: size, cornerRadius: 10)
        bg.fillColor = owned ? catalog.elementColor(s.element).withAlphaComponent(0.35) : SKColor(white: 1, alpha: 0.08)
        bg.strokeColor = SKColor(white: 1, alpha: owned ? 0.6 : 0.2)
        bg.lineWidth = 1.5
        cell.addChild(bg)

        let textH: CGFloat = 30
        let side = max(10, min(size.width - 8, size.height - textH - 6))
        let art = SKSpriteNode(texture: catalog.dragonTexture(s), size: CGSize(width: side, height: side))
        art.position = CGPoint(x: 0, y: size.height / 2 - 3 - side / 2)
        art.zPosition = 1
        if !owned {
            art.color = SKColor(red: 0.06, green: 0.08, blue: 0.16, alpha: 1)
            art.colorBlendFactor = 1
            art.alpha = 0.9
        }
        cell.addChild(art)

        let name = Format.label(s.name, size: min(12, size.width * 0.13), color: owned ? .white : SKColor(white: 0.8, alpha: 1))
        name.position = CGPoint(x: 0, y: -size.height / 2 + textH - 9)
        name.zPosition = 2
        cell.addChild(name)
        let elements = s.elements.map { catalog.elementName($0) }.joined(separator: " · ")
        let el = Format.label(elements, size: min(10, size.width * 0.11), bold: false,
                              color: catalog.elementColor(s.element))
        el.position = CGPoint(x: 0, y: -size.height / 2 + 8)
        el.zPosition = 2
        cell.addChild(el)
        return cell
    }
}
