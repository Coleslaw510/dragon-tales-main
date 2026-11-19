import SpriteKit

/// Simple SpriteKit actions: tap bounce, idle bob, egg wobble, coin pop and fly-to-HUD.
enum Effects {
    static func tapBounce() -> SKAction {
        let up = SKAction.scale(to: 1.12, duration: 0.08)
        up.timingMode = .easeOut
        let down = SKAction.scale(to: 0.95, duration: 0.08)
        let settle = SKAction.scale(to: 1.0, duration: 0.1)
        return SKAction.sequence([up, down, settle])
    }

    static func bounce(_ node: SKNode) {
        node.removeAction(forKey: "bounce")
        node.setScale(1)
        node.run(tapBounce(), withKey: "bounce")
    }

    static func idleBob(amplitude: CGFloat = 7) -> SKAction {
        let duration = 0.8 + Double.random(in: 0...0.4)
        let up = SKAction.moveBy(x: 0, y: amplitude, duration: duration)
        up.timingMode = .easeInEaseOut
        let down = up.reversed()
        return SKAction.sequence([SKAction.wait(forDuration: Double.random(in: 0...0.8)),
                                  SKAction.repeatForever(SKAction.sequence([up, down]))])
    }

    static func wobble() -> SKAction {
        let left = SKAction.rotate(toAngle: 0.18, duration: 0.09)
        let right = SKAction.rotate(toAngle: -0.18, duration: 0.09)
        let center = SKAction.rotate(toAngle: 0, duration: 0.09)
        return SKAction.repeatForever(SKAction.sequence([left, right, left, right, center,
                                                         SKAction.wait(forDuration: 0.7)]))
    }

    /// "+N" that rises and fades at `p` (in `parent` coordinates).
    static func coinPop(amount: Int, at p: CGPoint, in parent: SKNode) {
        let label = Format.label("+\(Format.gold(amount))", size: 56, color: Palette.gold)
        label.fontName = "AvenirNext-Heavy"
        label.position = p
        label.zPosition = 900
        label.setScale(0.4)
        parent.addChild(label)
        let rise = SKAction.group([SKAction.scale(to: 1, duration: 0.15),
                                   SKAction.moveBy(x: 0, y: 120, duration: 0.9)])
        let fade = SKAction.sequence([SKAction.wait(forDuration: 0.55), SKAction.fadeOut(withDuration: 0.35)])
        label.run(SKAction.sequence([SKAction.group([rise, fade]), SKAction.removeFromParent()]))
    }

    /// Coins burst at `from` and fly to `to` (both in `parent` coordinates).
    static func flyCoins(count: Int, from: CGPoint, to: CGPoint, in parent: SKNode,
                         texture: SKTexture, onArrive: @escaping () -> Void) {
        for i in 0..<max(1, count) {
            let coin = SKSpriteNode(texture: texture, size: CGSize(width: 30, height: 30))
            coin.position = CGPoint(x: from.x + CGFloat.random(in: -16...16),
                                    y: from.y + CGFloat.random(in: -16...16))
            coin.zPosition = 950
            coin.setScale(0.2)
            parent.addChild(coin)
            let pop = SKAction.group([SKAction.scale(to: 1, duration: 0.15),
                                      SKAction.moveBy(x: CGFloat.random(in: -30...30),
                                                      y: CGFloat.random(in: 20...50), duration: 0.15)])
            let fly = SKAction.move(to: to, duration: 0.5)
            fly.timingMode = .easeIn
            coin.run(SKAction.sequence([SKAction.wait(forDuration: 0.05 * Double(i)), pop, fly,
                                        SKAction.run(onArrive), SKAction.removeFromParent()]))
        }
    }
}
