//SceneDelegate
import UIKit
import SwiftUI
import WidgetKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        let contentView = ContentView() // 여기서 SwiftUI 앱의 진입점을 설정합니다.

        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: contentView)
            self.window = window
            window.makeKeyAndVisible()
        }
    }
    
    // 씬이 포어그라운드로 진입할 때 호출
    func sceneWillEnterForeground(_ scene: UIScene) {
        print("🔄 Scene will enter foreground - 라이브 액티비티 업데이트")
        LiveActivityManager.shared.updateLiveActivity()
    }
    
    // 씬이 활성화될 때 호출
    func sceneDidBecomeActive(_ scene: UIScene) {
        print("🔄 Scene did become active - 라이브 액티비티 업데이트")
        LiveActivityManager.shared.updateLiveActivity()
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    // 씬이 백그라운드로 이동할 때 호출
    func sceneDidEnterBackground(_ scene: UIScene) {
        print("🔄 Scene did enter background - 라이브 액티비티 최종 업데이트")
        LiveActivityManager.shared.updateLiveActivity()
    }
}
