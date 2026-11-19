import SpriteKit

/// Pan and pinch-zoom for the island camera. Zoom limits come from economy.json
/// (`minZoom`/`maxZoom`, used as camera scale: larger = further out).
final class CameraController {
    let camera: SKCameraNode
    let minScale: CGFloat
    let maxScale: CGFloat
    var bounds = CGRect(x: -950, y: -800, width: 1900, height: 1600)

    init(camera: SKCameraNode, minScale: CGFloat, maxScale: CGFloat) {
        self.camera = camera
        self.minScale = minScale
        self.maxScale = maxScale
    }

    /// `d` is a finger delta in view points (y down).
    func pan(byViewDelta d: CGPoint) {
        let s = camera.xScale
        camera.position = CGPoint(x: camera.position.x - d.x * s, y: camera.position.y + d.y * s)
        clampPosition()
    }

    /// Pinch factor > 1 zooms in.
    func zoom(by factor: CGFloat) {
        guard factor > 0 else { return }
        setScale(camera.xScale / factor)
    }

    func setScale(_ s: CGFloat) {
        camera.setScale(min(maxScale, max(minScale, s)))
        clampPosition()
    }

    func fit(width: CGFloat, viewWidth: CGFloat) {
        setScale(width / max(1, viewWidth))
    }

    private func clampPosition() {
        var p = camera.position
        p.x = min(bounds.maxX, max(bounds.minX, p.x))
        p.y = min(bounds.maxY, max(bounds.minY, p.y))
        camera.position = p
    }
}
