import SpriteKit

enum Palette {
    static let accent = SKColor(red: 0.98, green: 0.62, blue: 0.16, alpha: 1)
    static let go = SKColor(red: 0.20, green: 0.66, blue: 0.36, alpha: 1)
    static let stop = SKColor(red: 0.84, green: 0.28, blue: 0.26, alpha: 1)
    static let muted = SKColor(red: 0.30, green: 0.36, blue: 0.52, alpha: 1)
    static let panel = SKColor(red: 0.13, green: 0.17, blue: 0.29, alpha: 0.97)
    static let gold = SKColor(red: 1.0, green: 0.86, blue: 0.32, alpha: 1)
}

/// Rounded tappable button. The scene finds it by walking up from hit nodes.
final class ButtonNode: SKSpriteNode {
    var action: (() -> Void)?
    var isEnabled = true {
        didSet { alpha = isEnabled ? 1 : 0.45 }
    }
    let label: SKLabelNode
    private let background: SKShapeNode

    init(title: String, size: CGSize, color: SKColor, fontSize: CGFloat = 18,
         action: (() -> Void)? = nil) {
        label = Format.label(title, size: fontSize)
        background = SKShapeNode(rectOf: size, cornerRadius: min(14, size.height / 2))
        super.init(texture: nil, color: .clear, size: size)
        background.fillColor = color
        background.strokeColor = SKColor(white: 1, alpha: 0.85)
        background.lineWidth = 2
        background.zPosition = 1
        addChild(background)
        label.zPosition = 2
        addChild(label)
        self.action = action
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) not used") }

    func setFill(_ color: SKColor) { background.fillColor = color }

    func press() {
        guard isEnabled else { return }
        Effects.bounce(self)
        action?()
    }
}
