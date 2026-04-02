import SwiftUI

struct MainPageView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()

                NavigationLink(destination: HealMeView()) {
                    OptionCardView(
                        title: "Heal Me",
                        description: "Help us to stabilise your heart rate",
                        imageName: "heart.fill"
                    )
                }
                .padding(.horizontal)

                Spacer()

                NavigationLink(destination: MatchMeView()) {
                    OptionCardView(
                        title: "Match Me",
                        description: "Match your music to your heart rate",
                        imageName: "figure.stand.line.dotted.figure.stand"
                    )
                }
                .padding(.horizontal)

                Spacer()

                NavigationLink(destination: PushMeView()) {
                    OptionCardView(
                        title: "Push Me",
                        description: "Speed up the music along with your heartbeat",
                        imageName: "figure.handball"
                    )
                }
                .padding(.horizontal)

                Spacer()
            }
            .safeAreaInset(edge: .top) {
                VStack {
                    Text("Choose your mode")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.top, 18)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 70)
                .background(Color.black)
            }
            .background(Color.black.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}


struct OptionCardView: View {
    var title: String
    var description: String
    var imageName: String
    var isAsset: Bool = false

    var body: some View {
        HStack(spacing: 16) {
            if isAsset {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
            } else {
                Image(systemName: imageName)
                    .font(.system(size: 40))
                    .foregroundColor(.purple)
                    .frame(width: 60, height: 60)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title2)
                    .foregroundColor(.white)

                Text(description)
                    .font(.body)
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
        .padding()
        .background(Color.spotifyBackground)
        .cornerRadius(12)
    }
}

#Preview {
    MainPageView()
}
