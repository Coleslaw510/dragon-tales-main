import SwiftUI
import SpriteKit

@main
struct DragonTalesApp: App {
    var body: some Scene {
        WindowGroup {
            SpriteView(scene: GameScene.make())
                .ignoresSafeArea()
                .statusBarHidden(true)
        }
    }
}
