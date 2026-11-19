import SpriteKit

/// Number/time formatting and a label factory shared by HUD and overlays.
enum Format {
    private static let numbers: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f
    }()

    static func gold(_ value: Int) -> String {
        numbers.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    static func countdown(_ seconds: TimeInterval) -> String {
        let s = max(0, Int(seconds.rounded(.up)))
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, sec) }
        return String(format: "%d:%02d", m, sec)
    }

    static func label(_ text: String, size: CGFloat, bold: Bool = true,
                      color: SKColor = .white) -> SKLabelNode {
        let l = SKLabelNode(fontNamed: bold ? "AvenirNext-Bold" : "AvenirNext-Medium")
        l.text = text
        l.fontSize = size
        l.fontColor = color
        l.verticalAlignmentMode = .center
        l.horizontalAlignmentMode = .center
        return l
    }
}
