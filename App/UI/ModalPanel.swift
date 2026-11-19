import SpriteKit

/// Dimmed full-screen overlay with a centered panel, title and close button.
/// Added to the camera; the scene routes taps to its buttons while it is open.
class ModalPanel: SKNode {
    let panelSize: CGSize
    var onClose: (() -> Void)?
    var closesOnOutsideTap = true

    init(title: String, panelSize: CGSize, sceneSize: CGSize) {
        self.panelSize = panelSize
        super.init()
        zPosition = 500
        let dim = SKSpriteNode(color: SKColor(white: 0, alpha: 0.55),
                               size: CGSize(width: sceneSize.width * 2, height: sceneSize.height * 2))
        addChild(dim)
        let panel = SKShapeNode(rectOf: panelSize, cornerRadius: 22)
        panel.fillColor = Palette.panel
        panel.strokeColor = SKColor(white: 1, alpha: 0.8)
        panel.lineWidth = 3
        panel.zPosition = 1
        addChild(panel)
        let titleLabel = Format.label(title, size: 26)
        titleLabel.fontName = "AvenirNext-Heavy"
        titleLabel.position = CGPoint(x: 0, y: panelSize.height / 2 - 36)
        addContent(titleLabel)
        let close = ButtonNode(title: "✕", size: CGSize(width: 44, height: 44), color: Palette.muted, fontSize: 20)
        close.position = CGPoint(x: panelSize.width / 2 - 32, y: panelSize.height / 2 - 32)
        close.action = { [weak self] in self?.onClose?() }
        addContent(close)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) not used") }

    func addContent(_ node: SKNode) {
        node.zPosition = max(node.zPosition, 3)
        addChild(node)
    }

    /// `p` in this node's coordinates.
    func panelContains(_ p: CGPoint) -> Bool {
        abs(p.x) <= panelSize.width / 2 && abs(p.y) <= panelSize.height / 2
    }
}
