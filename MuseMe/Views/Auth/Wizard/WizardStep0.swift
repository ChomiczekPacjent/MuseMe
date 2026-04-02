import SwiftUI

struct WizardStep0: View {
    @Binding var profileData: ProfileData

    var body: some View {
        VStack {
            SegmentedProgressBar(currentStep: 1, totalSteps: 6)
                .padding([.horizontal, .top])
            
            Spacer(minLength: 25)

            Text("Let us get to know you better.")
                .font(.title)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding()
            
            Spacer()
            
            HStack {
                NavigationLink(destination: MainContainerView()) {
                    Text("Ask me later")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray)
                        .cornerRadius(8)
                }
                
                NavigationLink(destination: WizardStep1(profileData: $profileData)) {
                    Text("Next")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.purple)
                        .cornerRadius(8)
                }
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
                    .offset(x: -100) 
                    .ignoresSafeArea()
            }
        )          .navigationBarHidden(true)
    }
}
