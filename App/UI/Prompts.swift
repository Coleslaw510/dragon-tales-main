import SpriteKit

/// Small modal builders: a message with buttons, and the habitat picker for hatching.
enum Prompts {
    typealias ButtonSpec = (title: String, color: SKColor, action: () -> Void)

    static func message(title: String, text: String, buttons: [ButtonSpec], sceneSize: CGSize) -> ModalPanel {
        let w = min(sceneSize.width - 40, 380)
        let h: CGFloat = 260
        let m = ModalPanel(title: title, panelSize: CGSize(width: w, height: h), sceneSize: sceneSize)
        let body = Format.label(text, size: 17, bold: false)
        body.numberOfLines = 0
        body.preferredMaxLayoutWidth = w - 40
        body.position = CGPoint(x: 0, y: 14)
        m.addContent(body)
        let count = CGFloat(max(1, buttons.count))
        let bw = (w - 30 - (count - 1) * 10) / count
        for (i, spec) in buttons.enumerated() {
            let b = ButtonNode(title: spec.title, size: CGSize(width: bw, height: 46), color: spec.color,
                               action: spec.action)
            b.position = CGPoint(x: -w / 2 + 15 + bw / 2 + CGFloat(i) * (bw + 10), y: -h / 2 + 40)
            m.addContent(b)
        }
        return m
    }

    static func habitatPicker(species: DragonSpecies, options: [(id: Int, title: String)],
                              sceneSize: CGSize, onPick: @escaping (Int) -> Void) -> ModalPanel {
        let shown = Array(options.prefix(8))
        let w = min(sceneSize.width - 40, 380)
        let rowH: CGFloat = 50
        let h = 140 + CGFloat(shown.count) * (rowH + 10)
        let m = ModalPanel(title: "Hatch \(species.name)", panelSize: CGSize(width: w, height: h),
                           sceneSize: sceneSize)
        let sub = Format.label("Pick a habitat for your dragon", size: 15, bold: false)
        sub.position = CGPoint(x: 0, y: h / 2 - 72)
        m.addContent(sub)
        for (i, option) in shown.enumerated() {
            let id = option.id
            let b = ButtonNode(title: option.title, size: CGSize(width: w - 40, height: rowH),
                               color: Palette.go, fontSize: 17, action: { onPick(id) })
            b.position = CGPoint(x: 0, y: h / 2 - 120 - CGFloat(i) * (rowH + 10))
            m.addContent(b)
        }
        return m
    }
}
