import SwiftUI
import SpriteKit

@main
struct DragonTalesApp: App {
    @State private var scene = GameScene.make()

    var body: some Scene {
        WindowGroup {
            SpriteView(scene: scene)
                .ignoresSafeArea()
                .statusBarHidden(true)
        }
    }
}
