import SpriteKit
import UIKit

/// Touch routing: modal > HUD buttons > placement ghost drag > world taps; drag pans, pinch zooms.
extension GameScene {
    func installGestures(in view: SKView) {
        guard pinch == nil else { return }
        let p = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        view.addGestureRecognizer(p)
        pinch = p
    }

    @objc func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
        guard modal == nil, cameraCtl != nil else { return }
        switch recognizer.state {
        case .began:
            isPinching = true
            trackedTouch = nil
        case .changed:
            cameraCtl.zoom(by: recognizer.scale)
            recognizer.scale = 1
        default:
            isPinching = false
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard trackedTouch == nil, !isPinching, let t = touches.first, let view = view else { return }
        trackedTouch = t
        touchStart = t.location(in: view)
        touchLast = touchStart
        isPanning = false
        draggingGhost = false
        if modal == nil, let p = placement {
            let wp = t.location(in: world)
            if p.contains(wp) {
                draggingGhost = true
                dragOffset = CGPoint(x: p.ghost.position.x - wp.x, y: p.ghost.position.y - wp.y)
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = trackedTouch, touches.contains(t), !isPinching, let view = view else { return }
        let loc = t.location(in: view)
        let dx = loc.x - touchStart.x
        let dy = loc.y - touchStart.y
        if !isPanning, dx * dx + dy * dy > 64 {
            isPanning = true
        }
        defer { touchLast = loc }
        guard isPanning, modal == nil else { return }
        if draggingGhost, let p = placement {
            let wp = t.location(in: world)
            p.move(toWorld: CGPoint(x: wp.x + dragOffset.x, y: wp.y + dragOffset.y))
            hud.confirmButton.isEnabled = p.isValid
        } else {
            cameraCtl.pan(byViewDelta: CGPoint(x: loc.x - touchLast.x, y: loc.y - touchLast.y))
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = trackedTouch, touches.contains(t) else { return }
        trackedTouch = nil
        if !isPanning && !isPinching { handleTap(t) }
        isPanning = false
        draggingGhost = false
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        trackedTouch = nil
        isPanning = false
        draggingGhost = false
    }

    // MARK: Taps

    private func handleTap(_ t: UITouch) {
        if let m = modal {
            let p = t.location(in: m)
            if let b = button(in: m.nodes(at: p)) {
                b.press()
            } else if m.closesOnOutsideTap && !m.panelContains(p) {
                closeModal()
            }
            return
        }
        if let b = button(in: hud.nodes(at: t.location(in: hud))) {
            b.press()
            return
        }
        guard placement == nil else { return }
        tapWorld(world.nodes(at: t.location(in: world)))
    }

    private func button(in nodes: [SKNode]) -> ButtonNode? {
        for n in nodes {
            var current: SKNode? = n
            while let node = current {
                if let b = node as? ButtonNode, !b.isHidden { return b }
                current = node.parent
            }
        }
        return nil
    }

    /// Picks the most specific tapped object: egg > dragon > habitat > nursery.
    private func tapWorld(_ nodes: [SKNode]) {
        var egg: EggNode?
        var dragon: DragonNode?
        var habitat: HabitatNode?
        var nursery: NurseryNode?
        for n in nodes {
            var current: SKNode? = n
            while let node = current {
                if let e = node as? EggNode, egg == nil {
                    egg = e
                } else if let d = node as? DragonNode, dragon == nil {
                    dragon = d
                } else if let h = node as? HabitatNode {
                    if let best = habitat, best.zPosition >= h.zPosition {} else { habitat = h }
                } else if let ns = node as? NurseryNode {
                    nursery = ns
                }
                current = node.parent
            }
        }
        if let e = egg {
            tapEgg(e.eggId)
        } else if let d = dragon {
            Effects.bounce(d)
            if let h = d.parent?.parent as? HabitatNode { collect(h) }
            select(.dragon(d.dragonId))
        } else if let h = habitat {
            Effects.bounce(h)
            collect(h)
            select(.habitat(h.buildingId))
        } else if let n = nursery {
            Effects.bounce(n)
            select(.nursery)
            if let ready = firstReadyEgg() { tapEgg(ready) }
        } else {
            select(nil)
        }
    }
}
