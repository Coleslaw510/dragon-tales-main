import SpriteKit
import UIKit

/// Camera-attached HUD: gold + gems, Shop button, Dragon Book corner button, info bar for
/// the selection with an optional gem speed-up button, toasts, and Confirm/Cancel for placement.
final class HUD: SKNode {
    let coinIcon = SKSpriteNode(texture: Catalog.shared.coinTexture, size: CGSize(width: 38, height: 38))
    let shopButton: ButtonNode
    let confirmButton: ButtonNode
    let cancelButton: ButtonNode
    let speedUpButton: ButtonNode
    let bookButton: ButtonNode
    let gemIcon = SKSpriteNode(texture: Catalog.shared.gemTexture, size: CGSize(width: 30, height: 30))

    private let goldPill = SKShapeNode(rectOf: CGSize(width: 180, height: 46), cornerRadius: 23)
    private let goldLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    private let gemPill = SKShapeNode(rectOf: CGSize(width: 120, height: 36), cornerRadius: 18)
    private let gemLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    private let speedGem = SKSpriteNode(texture: Catalog.shared.gemTexture, size: CGSize(width: 24, height: 24))
    private var infoPill = SKShapeNode()
    private let infoLabel = Format.label("", size: 14)
    private let hintLabel = Format.label("Drag the habitat, then Confirm", size: 16)
    private let toastLabel = Format.label("", size: 18, color: Palette.gold)

    init(onShop: @escaping () -> Void, onConfirm: @escaping () -> Void, onCancel: @escaping () -> Void,
         onSpeedUp: @escaping () -> Void, onBook: @escaping () -> Void) {
        shopButton = ButtonNode(title: "Shop", size: CGSize(width: 104, height: 46), color: Palette.accent,
                                fontSize: 20, action: onShop)
        confirmButton = ButtonNode(title: "Confirm", size: CGSize(width: 130, height: 48), color: Palette.go,
                                   action: onConfirm)
        cancelButton = ButtonNode(title: "Cancel", size: CGSize(width: 130, height: 48), color: Palette.stop,
                                  action: onCancel)
        speedUpButton = ButtonNode(title: "Speed up for 1", size: CGSize(width: 210, height: 42),
                                   color: Palette.gem, fontSize: 16, action: onSpeedUp)
        bookButton = ButtonNode(title: "📖", size: CGSize(width: 40, height: 40),
                                color: SKColor(white: 0, alpha: 0.35), fontSize: 20, action: onBook)
        super.init()
        goldPill.fillColor = SKColor(white: 0, alpha: 0.5)
        goldPill.strokeColor = Palette.gold
        goldPill.lineWidth = 2
        addChild(goldPill)
        coinIcon.zPosition = 1
        addChild(coinIcon)
        goldLabel.fontSize = 22
        goldLabel.fontColor = .white
        goldLabel.horizontalAlignmentMode = .left
        goldLabel.verticalAlignmentMode = .center
        goldLabel.zPosition = 1
        addChild(goldLabel)
        gemPill.fillColor = SKColor(white: 0, alpha: 0.5)
        gemPill.strokeColor = Palette.gem
        gemPill.lineWidth = 2
        addChild(gemPill)
        gemIcon.zPosition = 1
        addChild(gemIcon)
        gemLabel.fontSize = 18
        gemLabel.fontColor = .white
        gemLabel.horizontalAlignmentMode = .left
        gemLabel.verticalAlignmentMode = .center
        gemLabel.zPosition = 1
        addChild(gemLabel)
        addChild(shopButton)
        bookButton.alpha = 0.85
        addChild(bookButton)
        speedUpButton.label.position = CGPoint(x: -12, y: 0)
        speedGem.position = CGPoint(x: 84, y: 0)
        speedGem.zPosition = 3
        speedUpButton.addChild(speedGem)
        speedUpButton.isHidden = true
        addChild(speedUpButton)
        infoLabel.numberOfLines = 2
        infoLabel.zPosition = 1
        addChild(infoLabel)
        hintLabel.fontName = "AvenirNext-Heavy"
        for node in [confirmButton, cancelButton, hintLabel] as [SKNode] {
            node.isHidden = true
            addChild(node)
        }
        toastLabel.fontName = "AvenirNext-Heavy"
        toastLabel.alpha = 0
        toastLabel.numberOfLines = 2
        addChild(toastLabel)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) not used") }

    func layout(size: CGSize, insets: UIEdgeInsets) {
        let top = size.height / 2 - max(insets.top, 20) - 30
        let bottom = -size.height / 2 + max(insets.bottom, 12) + 34
        goldPill.position = CGPoint(x: -size.width / 2 + 16 + 90, y: top)
        coinIcon.position = CGPoint(x: goldPill.position.x - 64, y: top)
        goldLabel.position = CGPoint(x: goldPill.position.x - 38, y: top)
        shopButton.position = CGPoint(x: size.width / 2 - 16 - 52, y: top)
        gemPill.position = CGPoint(x: -size.width / 2 + 16 + 60, y: top - 46)
        gemIcon.position = CGPoint(x: gemPill.position.x - 42, y: top - 46)
        gemLabel.position = CGPoint(x: gemPill.position.x - 22, y: top - 46)
        bookButton.position = CGPoint(x: size.width / 2 - 16 - 20, y: bottom + 58)
        speedUpButton.position = CGPoint(x: 0, y: bottom + 58)

        infoPill.removeFromParent()
        infoPill = SKShapeNode(rectOf: CGSize(width: size.width - 32, height: 58), cornerRadius: 16)
        infoPill.fillColor = SKColor(white: 0, alpha: 0.55)
        infoPill.strokeColor = SKColor(white: 1, alpha: 0.5)
        infoPill.position = CGPoint(x: 0, y: bottom)
        infoPill.isHidden = infoLabel.isHidden
        addChild(infoPill)
        infoLabel.preferredMaxLayoutWidth = size.width - 56
        infoLabel.position = infoPill.position

        cancelButton.position = CGPoint(x: -80, y: bottom + 80)
        confirmButton.position = CGPoint(x: 80, y: bottom + 80)
        hintLabel.position = CGPoint(x: 0, y: bottom + 132)
        toastLabel.preferredMaxLayoutWidth = size.width - 40
        toastLabel.position = CGPoint(x: 0, y: top - 100)
    }

    /// HUD coin icon position in the HUD's parent (camera) coordinates.
    var coinTarget: CGPoint {
        CGPoint(x: position.x + coinIcon.position.x, y: position.y + coinIcon.position.y)
    }

    func setGold(_ gold: Int) {
        goldLabel.text = Format.gold(gold)
    }

    func setGems(_ gems: Int) {
        gemLabel.text = Format.gold(gems)
    }

    /// Shows "Speed up for X" (gem icon) for the selected timer; dimmed when unaffordable.
    func setSpeedUp(cost: Int?, affordable: Bool) {
        guard let cost = cost, cost > 0, confirmButton.isHidden else {
            speedUpButton.isHidden = true
            return
        }
        speedUpButton.isHidden = false
        speedUpButton.label.text = "Speed up for \(cost)"
        speedUpButton.setFill(affordable ? Palette.gem : Palette.muted)
        speedUpButton.alpha = affordable ? 1 : 0.7
    }

    func bumpGems() {
        Effects.bounce(gemIcon)
    }

    func bumpGold() {
        Effects.bounce(coinIcon)
    }

    func showInfo(_ text: String?) {
        let hidden = (text ?? "").isEmpty
        infoLabel.isHidden = hidden
        infoPill.isHidden = hidden
        if let text = text, infoLabel.text != text { infoLabel.text = text }
    }

    func toast(_ text: String) {
        toastLabel.removeAllActions()
        toastLabel.text = text
        toastLabel.alpha = 1
        toastLabel.run(SKAction.sequence([SKAction.wait(forDuration: 2.0), SKAction.fadeOut(withDuration: 0.4)]))
    }

    func setPlacementMode(_ on: Bool, hint: String?) {
        confirmButton.isHidden = !on
        cancelButton.isHidden = !on
        hintLabel.isHidden = !on
        shopButton.isHidden = on
        bookButton.isHidden = on
        if on { speedUpButton.isHidden = true }
        if let hint = hint { hintLabel.text = hint }
    }
}
