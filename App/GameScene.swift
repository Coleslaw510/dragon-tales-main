import SpriteKit

final class GameScene: SKScene {
    static func make() -> GameScene {
        let scene = GameScene(size: CGSize(width: 1248, height: 1056))
        scene.scaleMode = .aspectFill
        scene.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        return scene
    }

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.55, green: 0.80, blue: 0.93, alpha: 1)
        let title = SKLabelNode(text: "Dragon Tales")
        title.fontName = "AvenirNext-Bold"
        title.fontSize = 48
        title.fontColor = .white
        title.position = CGPoint(x: 0, y: 24)
        addChild(title)
    }
}
