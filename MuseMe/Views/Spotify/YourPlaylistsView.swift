import SwiftUI

struct YourPlaylistsView: View {
    @ObservedObject var auth = SpotifyAuthManager.shared
    @ObservedObject var playerVM = SpotifyPlayerViewModel.shared

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Your Library")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxHeight: .infinity, alignment: .center)

                Spacer()

                Button(action: {
                    if let url = URL(string: "spotify://") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack(spacing: 4) {
                        Image("wspotify")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                        Text("Spotify")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .frame(maxHeight: .infinity, alignment: .center)
                }
            }
            .frame(height: 44)
            .padding(.horizontal, 16)
            .padding(.top, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(auth.userPlaylists, id: \.id) { playlist in
                        Button(action: {
                            if playlist.id == "liked-songs" {
                                playerVM.playLikedSongsContextViaWebAPI()
                                playerVM.preloadLikedTracks()
                            } else if let uri = playlist.uri {
                                playerVM.playPlaylistURI(uri)
                            }
                        }) {
                            HStack {
                                if playlist.id == "liked-songs" {
                                    ZStack {
                                        LinearGradient(
                                            colors: [Color.purple, Color.blue],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                        Image(systemName: "heart.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 15, height: 15)
                                            .foregroundColor(.white)
                                    }
                                    .frame(width: 50, height: 50)
                                    .cornerRadius(8)
                                } else if let url = playlist.images?.first?.url,
                                          let imageURL = URL(string: url) {
                                    AsyncImage(url: imageURL) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        ProgressView()
                                    }
                                    .frame(width: 50, height: 50)
                                    .cornerRadius(8)
                                } else {
                                    Image(systemName: "music.note.list")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 50, height: 50)
                                        .cornerRadius(8)
                                        .foregroundColor(.gray)
                                }

                                Text(playlist.name)
                                    .foregroundColor(.white)
                                    .font(.subheadline)
                                    .padding(.leading, 8)

                                Spacer()
                            }
                            .padding(.horizontal, 16)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.top, 10)
            }
        }
        .background(Color.spotifyBackground)
        .onAppear {
            auth.fetchUserPlaylists()
            auth.fetchLikedSongsAsPlaylist()
        }
    }
}
