import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var sessionManager: SessionManager
    @EnvironmentObject var viewModel: AuthViewModel

    var body: some View {
        NavigationView {
            Group {
                if viewModel.userSession == nil {
                    LoginView()
                } else if !sessionManager.didCompleteWizard {
                    WizardContainerView(profileData: viewModel.profileData)
                } else {
                    MainContainerView()
                }
            }
            .onOpenURL { url in
                SpotifyAuthManager.shared.handleOpenURL(url: url)
            }
        }
    }
}
