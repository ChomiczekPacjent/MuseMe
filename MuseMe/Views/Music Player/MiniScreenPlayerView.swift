import SwiftUI

struct MiniScreenPlayerView: View {
    @Binding var isExpanded: Bool
    @ObservedObject var playerVM: SpotifyPlayerViewModel
    
    
    
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                if let artwork = playerVM.artwork {
                    Image(uiImage: artwork)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .cornerRadius(6)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 50, height: 50)
                        .cornerRadius(6)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(playerVM.trackName)
                            .font(.headline)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        if let bpm = playerVM.trackBPM {
                            Text("\(Int(bpm)) BPM")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Text(playerVM.trackArtist)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Button(action: {
                    playerVM.toggleLikeForCurrentTrack()
                }) {
                    Image(systemName: playerVM.isCurrentTrackLiked ? "heart.fill" : "heart")
                        .foregroundColor(.purple)
                        .font(.title3)
                }
                
                Button(action: {
                    playerVM.togglePlayPause()
                }) {
                    Image(systemName: playerVM.isPaused ? "play.fill" : "pause.fill")
                        .foregroundColor(.black)
                        .font(.title2)
                        .padding()
                        .background(Color.white)
                        .clipShape(Circle())
                }
                
                Button(action: {
                    playerVM.skipToNext()
                }) {
                    Image(systemName: "forward.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal)
            .padding(.top, 10)
        }
        .frame(maxWidth: .infinity)
        .background(Color(red: 35/255, green: 35/255, blue: 35/255))

        .onTapGesture {
            withAnimation {
                isExpanded = true
            }
        }
    }
}
