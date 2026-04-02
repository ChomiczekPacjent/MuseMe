import SwiftUI

struct ConnectView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var auth = SpotifyAuthManager.shared

    var body: some View {
        VStack(spacing: 24) {
            
            VStack(spacing: 4) {
                Text("Ready to listen?")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Text("Connect to your music service")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            Button {
                SpotifyAuthManager.shared.initiateSession()
            } label: {
                HStack {
                    Image("spotify")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 40)
                    Text("Continue with Spotify")
                        .fontWeight(.semibold)
                        .font(.system(size: 16))
                }
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(Color.green)
                .foregroundColor(.black)
                .cornerRadius(12)
            }

            Button {
            } label: {
                HStack {
                    Image("scsc")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 40)
                    Text("Continue with SoundCloud")
                        .fontWeight(.semibold)
                        .font(.system(size: 16))
                }
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(Color(red: 1.0, green: 0.333, blue: 0.0))
                .foregroundColor(.black)
                .cornerRadius(12)
            }

                Button {
                } label: {
                    HStack {
                        Image("applem")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 40)
                        Text("Continue with AppleMusic")
                            .fontWeight(.semibold)
                            .font(.system(size: 16))
                    }
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Color(red: 250/255, green: 44/255, blue: 86/255))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            

            Spacer()
        }
        .padding()
        .background(Color.spotifyBackground.ignoresSafeArea())
        .onReceive(NotificationCenter.default.publisher(for: .spotifyLoginSuccess)) { _ in
            print("ConnectView received spotifyLoginSuccess")
            dismiss()
        }
    }
}
