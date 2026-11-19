import SpriteKit

/// Shop section contents and the grid cell. Buildings: the (single, already placed) Nursery,
/// the Breeding Cave (buy + place), and others listed from economy.json until their milestone.
extension ShopOverlay {
    func eggItems() -> [Item] {
        catalog.baseSpecies.map { s -> Item in
            Item(title: s.name, subtitle: catalog.elementName(s.element) + " egg",
                 price: catalog.eggCost, texture: catalog.eggTexture(s),
                 color: catalog.elementColor(s.element), note: nil,
                 buy: { [weak self] in self?.onBuyEgg?(s) })
        }
    }

    func habitatItems() -> [Item] {
        catalog.economy.elements.map { e -> Item in
            let id = e.id
            return Item(title: "\(e.name) Habitat", subtitle: "Holds \(catalog.habitatCapacity)",
                        price: catalog.habitatCost, texture: catalog.habitatTexture(id),
                        color: catalog.elementColor(id), note: nil,
                        buy: { [weak self] in self?.onBuyHabitat?(id) })
        }
    }

    func buildingItems() -> [Item] {
        let blue = SKColor(red: 0.25, green: 0.48, blue: 0.85, alpha: 1)
        let soon: (String) -> () -> Void = { name in
            { [weak self] in self?.onUnavailable?("\(name) is coming soon") }
        }
        var list: [Item] = []
        let nurseryName = "Nursery"
        list.append(Item(title: nurseryName, subtitle: "Holds \(catalog.nurserySlots) eggs", price: 0,
                         texture: catalog.nurseryTexture, color: blue, note: "Owned",
                         buy: { [weak self] in self?.onUnavailable?("You already have the Nursery. Long-press it to move it.") }))
        list.append(Item(title: CaveRules.name, subtitle: "Breed dragons", price: CaveRules.cost,
                         texture: catalog.caveTexture, color: blue, note: nil,
                         buy: { [weak self] in self?.onBuyCave?() }))
        if let farm = catalog.economy.farms, let sprite = farm.sprite {
            let name = farm.name ?? "Farm"
            list.append(Item(title: name, subtitle: "Grows food", price: farm.cost ?? 0,
                             texture: catalog.buildingTexture(sprite), color: blue, note: "Coming soon",
                             buy: soon(name)))
        }
        for d in catalog.economy.shop.decorations ?? [] {
            list.append(Item(title: d.name, subtitle: "Decoration", price: d.cost,
                             texture: catalog.buildingTexture(d.sprite), color: blue, note: "Coming soon",
                             buy: soon(d.name)))
        }
        return list
    }

    func makeCell(_ item: Item, size: CGSize) -> ButtonNode {
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
        if let note = item.note {
            icon.alpha = 0.75
            let label = Format.label(note, size: 13, color: SKColor(white: 0.85, alpha: 1))
            label.position = CGPoint(x: 0, y: priceY)
            label.zPosition = 3
            cell.addChild(label)
            return cell
        }
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
