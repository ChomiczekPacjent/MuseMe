import SwiftUI

struct MainContainerView: View {

    @State private var isPlayerExpanded: Bool = false
    @StateObject var playerVM = SpotifyPlayerViewModel.shared
    @State private var selectedTab: FooterTab = .home
    @StateObject var healthStore = HealthStore()

    @State private var showConnectSheet: Bool = false
    @State private var showSpotifySheet: Bool = false

    var body: some View {
        ZStack(alignment: .bottom) {

            Color.spotifyBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {

                HeaderView(selectedTab: $selectedTab)
                    .padding(.top, 10)

                switch selectedTab {
                case .home:
                    HomeView()
                case .history:
                    HistoryView()
                case .vitals:
                    VitalsView(healthStore: healthStore)
                case .profile:
                    ProfileView()
                case .notifications:
                    NotificationsView()
                case .start:
                    MainPageView().environmentObject(playerVM)
                case .connect:
                    EmptyView()
                case .spotify:
                    EmptyView()
                }

                FooterView(
                    selectedTab: $selectedTab,
                    showConnectOverlay: $showConnectSheet,
                    homeAction: { },
                    historyAction: { },
                    vitalsAction: { },
                    startAction: { },
                    spotifyAction: {
                        if SpotifyAuthManager.shared.accessToken == nil {
                            showConnectSheet = true
                        } else {
                            showSpotifySheet = true
                        }
                    }
                )
            }

            if isPlayerExpanded {
                FullScreenPlayerView(isExpanded: $isPlayerExpanded, playerVM: playerVM)
                    .transition(.move(edge: .bottom))
                    .animation(.spring(), value: isPlayerExpanded)
                    .zIndex(20)
            }
        }
        .navigationBarHidden(true)
        .onReceive(NotificationCenter.default.publisher(for: .spotifyLoginSuccess)) { _ in
            print("🎉 Spotify login success — showing sheet with playlists")
            showConnectSheet = false
            showSpotifySheet = true
            SpotifyPlayerViewModel.shared.connect()
        }
        .sheet(isPresented: $showConnectSheet) {
            ConnectView()
                .presentationDetents([.medium])
                .presentationCornerRadius(24)
        }
        .sheet(isPresented: $showSpotifySheet) {
            SpotifyFullScreenView()
                .presentationDetents([.medium, .large])
                .presentationCornerRadius(24)
        }
    }
}

#Preview {
    MainContainerView()
}
