import SpriteKit
import UIKit

/// Camera-attached HUD: gold, Shop button, info bar for the selection, toasts,
/// and Confirm/Cancel for habitat placement.
final class HUD: SKNode {
    let coinIcon = SKSpriteNode(texture: Catalog.shared.coinTexture, size: CGSize(width: 38, height: 38))
    let shopButton: ButtonNode
    let confirmButton: ButtonNode
    let cancelButton: ButtonNode

    private let goldPill = SKShapeNode(rectOf: CGSize(width: 180, height: 46), cornerRadius: 23)
    private let goldLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    private var infoPill = SKShapeNode()
    private let infoLabel = Format.label("", size: 14)
    private let hintLabel = Format.label("Drag the habitat, then Confirm", size: 16)
    private let toastLabel = Format.label("", size: 18, color: Palette.gold)

    init(onShop: @escaping () -> Void, onConfirm: @escaping () -> Void, onCancel: @escaping () -> Void) {
        shopButton = ButtonNode(title: "Shop", size: CGSize(width: 104, height: 46), color: Palette.accent,
                                fontSize: 20, action: onShop)
        confirmButton = ButtonNode(title: "Confirm", size: CGSize(width: 130, height: 48), color: Palette.go,
                                   action: onConfirm)
        cancelButton = ButtonNode(title: "Cancel", size: CGSize(width: 130, height: 48), color: Palette.stop,
                                  action: onCancel)
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
        addChild(shopButton)
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
        toastLabel.position = CGPoint(x: 0, y: top - 70)
    }

    /// HUD coin icon position in the HUD's parent (camera) coordinates.
    var coinTarget: CGPoint {
        CGPoint(x: position.x + coinIcon.position.x, y: position.y + coinIcon.position.y)
    }

    func setGold(_ gold: Int) {
        goldLabel.text = Format.gold(gold)
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

    func setPlacementMode(_ on: Bool, element: String?) {
        confirmButton.isHidden = !on
        cancelButton.isHidden = !on
        hintLabel.isHidden = !on
        shopButton.isHidden = on
        if let element = element { hintLabel.text = "Drag the \(element) Habitat, then Confirm" }
    }
}
