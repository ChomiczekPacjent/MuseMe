import SwiftUI

struct FullScreenPlayerView: View {
    @Binding var isExpanded: Bool
    @ObservedObject var playerVM: SpotifyPlayerViewModel
    
    @State private var offset: CGFloat = 0
    @State private var sliderValue: Double = 0
    @State private var isEditingSlider = false
    
    @State private var basePosition: Double = 0
    @State private var lastUpdate: Date = Date()

    var body: some View {
        
        Spacer().frame(height: 100)

        VStack {
            Capsule()
                .fill(Color.gray)
                .frame(width: 40, height: 5)
                .padding(.top, 10)
            
            if let image = playerVM.artwork {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: 300)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(maxWidth: .infinity, maxHeight: 300)
            }

            
            Spacer().frame(height: 25)

            
            Text("\(playerVM.trackName) | BPM: \(playerVM.trackBPM != nil ? String(format: "%.0f", playerVM.trackBPM!) : "-")")
                .font(.subheadline)
                .lineLimit(5)
                .foregroundColor(.white)
            
            Spacer().frame(height: 0)

            HStack {
                Text(formatTime(sliderValue))
                    .foregroundColor(.white)
                Slider(
                    value: $sliderValue,
                    in: 0...max(playerVM.trackDuration, 1),
                    onEditingChanged: { editing in
                        isEditingSlider = editing
                        if !editing {
                            basePosition = sliderValue
                            lastUpdate = Date()
                            playerVM.seek(to: sliderValue)
                        }
                    }
                )
                .accentColor(.blue)
                Text(formatTime(playerVM.trackDuration))
                    .foregroundColor(.white)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { now in
                    if !isEditingSlider && !playerVM.isPaused {
                        let delta = now.timeIntervalSince(lastUpdate)
                        let newValue = basePosition + delta * 1
                        sliderValue = min(newValue, playerVM.trackDuration)
                    } else if playerVM.isPaused {
                        sliderValue = playerVM.currentPosition
                        basePosition = playerVM.currentPosition
                        lastUpdate = now
                    }
                }

            
            HStack(spacing: 40) {
                Button(action: {
                    playerVM.skipToPrevious()
                    basePosition = 0
                    lastUpdate = Date()
                }) {
                    Image(systemName: "backward.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.white)
                }
                
                Button(action: {
                    playerVM.togglePlayPause()
                    basePosition = playerVM.currentPosition
                    lastUpdate = Date()
                }) {
                    Image(systemName: playerVM.isPaused ? "play.circle.fill" : "pause.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.blue)
                }
                
                Button(action: {
                    playerVM.skipToNext()
                    basePosition = 0
                    lastUpdate = Date()
                }) {
                    Image(systemName: "forward.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.white)
                }
            }
            .padding()
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 18/255, green: 18/255, blue: 18/255))
        .cornerRadius(20)
        .shadow(radius: 5)
        .edgesIgnoringSafeArea(.all)
        .offset(y: offset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    offset = value.translation.height
                }
                .onEnded { value in
                    if value.translation.height > 100 {
                        withAnimation(.easeOut(duration: 0.3)) {
                            offset = 1000
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            isExpanded = false
                            offset = 0
                        }
                    } else {
                        withAnimation(.easeOut(duration: 0.3)) {
                            offset = 0
                        }
                    }
                }
        )
        .onAppear {
            sliderValue = playerVM.currentPosition
            basePosition = playerVM.currentPosition
            lastUpdate = Date()
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let totalSeconds = Int(time)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
