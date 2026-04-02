import SwiftUI

struct FooterView: View {
    @Binding var selectedTab: FooterTab
    @Binding var showConnectOverlay: Bool

    var homeAction: () -> Void
    var historyAction: () -> Void
    var vitalsAction: () -> Void
    var startAction: () -> Void
    var spotifyAction: () -> Void
    var body: some View {
        HStack(spacing: 0) {
            Button(action: {
                selectedTab = .home
                homeAction()
            }) {
                VStack {
                    Image(systemName: "house.fill")
                        .font(.title2)
                        .padding(.top, 2)

                    Text("Home")
                        .font(.footnote)
                }
                .foregroundColor(selectedTab == .home ? .purple : Color(white: 1.0, opacity: 0.7))
                .frame(maxWidth: .infinity)
            }

            Button(action: {
                selectedTab = .history
                historyAction()
            }) {
                VStack {
                    Image(systemName: "clock.fill")
                        .font(.title2)
                        .padding(.top, 2)

                    Text("History")
                        .font(.footnote)
                }
                .foregroundColor(selectedTab == .history ? .purple : Color(white: 1.0, opacity: 0.7))
                .frame(maxWidth: .infinity)
            }
            
            
            HStack {
                Spacer()

                Button(action: {
                    selectedTab = .start
                    startAction()
                }) {
                    VStack(spacing: 4) {
                        Image("finallogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 48, height: 48) 
                            .padding(.top, 2)

                        Text("Start")
                            .font(.footnote)
                    }
                    .foregroundColor(selectedTab == .start ? .purple : Color(white: 1.0, opacity: 0.7))
                    
                }

                Spacer()
            }


            Button(action: {
                selectedTab = .vitals
                vitalsAction()
            }) {
                VStack {
                    Image(systemName: "waveform.path.ecg")
                        .font(.title2)
                        .padding(.top, 2)

                    Text("Vitals")
                        .font(.footnote)
                }
                .foregroundColor(selectedTab == .vitals ? .purple : Color(white: 1.0, opacity: 0.7))
                .frame(maxWidth: .infinity)
            }
            
            

            Button(action: {
                spotifyAction()
            }) {
                VStack {
                        Image(systemName: "plus")
                        .font(.system(size: 28))
                            .padding(.top, 2)

                        Text("Connect")
                            .font(.footnote)
                    }
                .foregroundColor(selectedTab == .spotify ? .purple : Color(white: 1.0, opacity: 0.7))
                .frame(maxWidth: .infinity)
            }


        }
        .padding(.vertical, 10)
        .frame(height: 60)
        .background(Color.spotifyBackground)
        
    }
}
