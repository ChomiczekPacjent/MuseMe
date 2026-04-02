import SwiftUI

struct SpotifyFullScreenView: View {
    @ObservedObject var playerVM = SpotifyPlayerViewModel.shared
    @State private var showConnectView = false

    var body: some View {
        VStack(spacing: 0) {
            

            TabView {
                YourPlaylistsView()
                RecommendedView()
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            MiniScreenPlayerView(
                isExpanded: .constant(false),
                playerVM: playerVM
            )
            .padding(.bottom, 8)
            .ignoresSafeArea(edges: .bottom)

        }
        .frame(maxHeight: .infinity)
        .background(Color(red: 35/255, green: 35/255, blue: 35/255))
        .onAppear {
            SpotifyAuthManager.shared.fetchSpotifyUserInfo()
        }
        .onChange(of: playerVM.shouldShowConnectView) {
            if playerVM.shouldShowConnectView {
                showConnectView = true
            }
        }


        .sheet(isPresented: $showConnectView) {
            ConnectView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }

    }
}

