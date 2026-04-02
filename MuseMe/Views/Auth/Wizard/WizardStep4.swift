import SwiftUI

struct WizardStep4: View {
    @Environment(\.dismiss) var dismiss
    @Binding var profileData: ProfileData

    let genres = ["Pop", "Classical", "Hip Hop", "Jazz", "Electronic", "Rock", "Reggae", "Metal", "Folk", "R&B", "Country", "Latin", "Blues", "Phonk", "Indie", "Kobos"]
    
    @State private var selectedGenres: Set<String> = []
    
    var body: some View {
        VStack {
            SegmentedProgressBar(currentStep: 5, totalSteps: 6)
                .padding([.horizontal, .top])
            
            Spacer()
            
            Text("Select your favorite music genres")
                .font(.title)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding()
            
            Spacer()
            
            GeometryReader { geometry in
                ZStack {
                    ForEach(Array(genres.enumerated()), id: \.element) { index, genre in
                        Button(action: {
                            if selectedGenres.contains(genre) {
                                selectedGenres.remove(genre)
                            } else {
                                selectedGenres.insert(genre)
                            }
                            
                            profileData.genre = selectedGenres.sorted().joined(separator: ", ")
                        }) {
                            Text(genre)
                                .font(.caption2)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .frame(width: 50, height: 50)
                                .background(selectedGenres.contains(genre) ? Color.purple : Color.gray.opacity(0.3))
                                .clipShape(Circle())
                        }
                        .position(positionForGenre(index: index, in: geometry.size))
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .frame(height: 300)
            
            Spacer()
            
            HStack {
                Button(action: { dismiss() }) {
                    Text("Back")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray)
                        .cornerRadius(8)
                }
                
                NavigationLink(destination: WizardFinal(profileData: $profileData)) {
                    Text("Next")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.purple)
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            ZStack {
                Image("grad")
                    .resizable()
                    .scaledToFill()
                    .offset(x: 50)
                    .ignoresSafeArea()
                
                Color.black.opacity(0.4)
            }
        )
        .navigationBarHidden(true)
        .onAppear {
            selectedGenres = Set(
                profileData.genre
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
            )
        }
    }
    
    private func positionForGenre(index: Int, in size: CGSize) -> CGPoint {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let count = genres.count
        let angle = 2 * CGFloat.pi * CGFloat(index) / CGFloat(count)
        let radius = min(size.width, size.height) / 2
        let x = center.x + radius * cos(angle)
        let y = center.y + radius * sin(angle)
        return CGPoint(x: x, y: y)
    }
}
