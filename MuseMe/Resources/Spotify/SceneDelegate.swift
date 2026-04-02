import UIKit
import SwiftUI
import Firebase

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        // Sprawdź, czy masz zapisany token dostępu
        if let fullToken = UserDefaults.standard.string(forKey: accessTokenKey) {
            // Możesz przypisać token do Web API i App Remote
            SpotifyAuthManager.shared.accessToken = fullToken
        } else {
            print("Brak pełnego tokenu w UserDefaults")
        }

        //  FIREBASE
        FirebaseApp.configure()
        
        // Inicjalizowanie widoku głównego
        let contentView = ContentView().environmentObject(SessionManager.shared)
        window = UIWindow(frame: UIScreen.main.bounds)
        window!.windowScene = windowScene
        window!.rootViewController = UIHostingController(rootView: contentView)
        window!.makeKeyAndVisible()
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        print("SceneDelegate - Odebrano redirect URL: \(url.absoluteString)")
        
        // Obsługuje URL zwrócony po autoryzacji przez Spotify Web API
        SpotifyAuthManager.shared.handleOpenURL(url: url)
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Sprawdź, czy token wymaga odświeżenia (jeśli masz zapisany refreshToken)
        SpotifyAuthManager.shared.refreshAccessToken { newToken in
            if let token = newToken {
                print("SceneDelegate - Token odświeżony: \(token)")
            } else {
                print("SceneDelegate - Nie udało się odświeżyć tokena")
            }
        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Możesz dodać logikę rozłączania lub zapisywania stanu
    }
}
