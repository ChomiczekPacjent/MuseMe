//
//  RecommendedView.swift
//  MuseMe
//
//  Created by Błażej Faber on 07/04/2025.
//

import SwiftUI

struct RecommendedPlaylist: Identifiable {
    let id = UUID()
    let name: String
    let bpmRange: String
    let imageName: String
    let uri: String
}

struct RecommendedView: View {
    @ObservedObject var playerVM = SpotifyPlayerViewModel.shared

    let playlists: [RecommendedPlaylist] = [
        RecommendedPlaylist(
            name: "Brown Noise",
            bpmRange: "Ideal for focus & calm",
            imageName: "cloud.fill",
            uri: "spotify:album:45CPZsTjYpn8I3A5KI7iR7"
        ),
        RecommendedPlaylist(
            name: "White Noise",
            bpmRange: "Perfect for studying or sleep",
            imageName: "wind",
            uri: "spotify:playlist:37i9dQZF1DWUZ5bk6qqDSy"
        ),
        RecommendedPlaylist(
            name: "Green Noise",
            bpmRange: "Perfect for studying or sleep",
            imageName: "wind",
            uri: "spotify:playlist:37i9dQZF1DWUZ5bk6qqDSy"
            )
    ]

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Recommended For You")
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
                    ForEach(playlists) { playlist in
                        Button(action: {
                            print("▶️ Playing recommended: \(playlist.name)")
                            playerVM.play(uri: playlist.uri)
                        }) {
                            HStack {
                                ZStack {
                                    LinearGradient(
                                        colors: [Color.purple, Color.blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    Image(systemName: playlist.imageName)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                        .foregroundColor(.white)
                                }
                                .frame(width: 50, height: 50)
                                .cornerRadius(8)

                                VStack(alignment: .leading) {
                                    Text(playlist.name)
                                        .foregroundColor(.white)
                                        .font(.subheadline)
                                    Text(playlist.bpmRange)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
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
    }
}
