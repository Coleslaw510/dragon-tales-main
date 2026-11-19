import SpriteKit
import UIKit

/// Root scene: owns the park state, camera, HUD and island nodes.
/// Input is in GameScene+Input.swift, gameplay flows in GameScene+Actions.swift,
/// island nodes in Island/IslandBuilder.swift.
final class GameScene: SKScene {
    enum Selection: Equatable {
        case habitat(Int)
        case nursery
        case dragon(Int)
        case egg(Int)
    }

    let catalog = Catalog.shared
    var state: GameState!
    let world = SKNode()
    let cam = SKCameraNode()
    let sky = SKSpriteNode()
    var hud: HUD!
    var cameraCtl: CameraController!
    var grid: IslandGrid!
    var habitatNodes: [Int: HabitatNode] = [:]
    var nurseryNode: NurseryNode?
    var modal: ModalPanel?
    var placement: PlacementController?
    var selection: Selection?

    // Touch tracking (see GameScene+Input.swift)
    var trackedTouch: UITouch?
    var touchStart = CGPoint.zero
    var touchLast = CGPoint.zero
    var isPanning = false
    var isPinching = false
    var draggingGhost = false
    var dragOffset = CGPoint.zero
    var pinch: UIPinchGestureRecognizer?

    private var didSetup = false
    private var lastTick: TimeInterval = 0
    private var lastSave = Date()

    static func make() -> GameScene {
        let scene = GameScene(size: CGSize(width: 390, height: 844))
        scene.scaleMode = .resizeFill
        scene.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        return scene
    }

    override func didMove(to view: SKView) {
        view.isMultipleTouchEnabled = true
        installGestures(in: view)
        guard !didSetup else { return }
        didSetup = true
        backgroundColor = SKColor(red: 0.55, green: 0.80, blue: 0.93, alpha: 1)

        addChild(world)
        cam.zPosition = 1000
        addChild(cam)
        camera = cam
        sky.texture = catalog.texture("tiles/sky_background.jpg")
        sky.zPosition = -3000
        cam.addChild(sky)

        let island = catalog.economy.island
        grid = IslandGrid(island: island)
        cameraCtl = CameraController(camera: cam, minScale: CGFloat(island.minZoom),
                                     maxScale: CGFloat(island.maxZoom))
        let now = Date()
        let saved = SaveStore.load() ?? SaveStore.newGame(catalog: catalog, grid: grid, now: now)
        state = GameState(data: saved, catalog: catalog)
        if state.data.gems == nil { state.data.gems = catalog.startingGems }
        state.accrueAll(now: now)

        buildBackdrop()
        rebuildBuildings()

        hud = HUD(onShop: { [weak self] in self?.openShop() },
                  onConfirm: { [weak self] in self?.confirmPlacement() },
                  onCancel: { [weak self] in self?.cancelPlacement() },
                  onSpeedUp: { [weak self] in self?.speedUpSelected() },
                  onBook: { [weak self] in self?.openBook() })
        cam.addChild(hud)
        layoutForSize()
        cameraCtl.fit(width: 1150, viewWidth: size.width)
        observeLifecycle()
        tick()
        save()
        if state.habitats.isEmpty && state.data.eggs.isEmpty && state.data.dragons.isEmpty {
            hud.toast("Welcome! Tap Shop to buy a habitat and an egg.")
        }
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        layoutForSize()
    }

    private func layoutForSize() {
        guard hud != nil else { return }
        let ts = sky.texture?.size() ?? .zero
        if ts.width > 0, ts.height > 0 {
            let s = max(size.width / ts.width, size.height / ts.height)
            sky.size = CGSize(width: ts.width * s, height: ts.height * s)
        } else {
            sky.size = size
        }
        hud.layout(size: size, insets: view?.safeAreaInsets ?? .zero)
    }

    override func update(_ currentTime: TimeInterval) {
        guard didSetup else { return }
        if currentTime - lastTick >= 0.5 {
            lastTick = currentTime
            tick()
        }
    }

    /// Accrue income, refresh timers and labels, autosave.
    func tick() {
        let now = Date()
        state.accrueAll(now: now)
        nurseryNode?.sync(eggs: state.data.eggs, now: now, catalog: catalog)
        for (id, node) in habitatNodes {
            node.setStored(state.storedGold(habitatId: id), cap: state.storageCap(habitatId: id))
        }
        hud.setGold(state.gold)
        hud.setGems(state.gems)
        refreshInfo()
        if now.timeIntervalSince(lastSave) > 15 { save() }
    }

    func save() {
        lastSave = Date()
        SaveStore.save(state.data)
    }

    // MARK: App lifecycle

    private func observeLifecycle() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(appWillResignActive),
                       name: UIApplication.willResignActiveNotification, object: nil)
        nc.addObserver(self, selector: #selector(appWillResignActive),
                       name: UIApplication.didEnterBackgroundNotification, object: nil)
        nc.addObserver(self, selector: #selector(appDidBecomeActive),
                       name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    @objc private func appWillResignActive() {
        guard didSetup else { return }
        state.accrueAll(now: Date())
        save()
    }

    @objc private func appDidBecomeActive() {
        guard didSetup else { return }
        tick()
    }
}
