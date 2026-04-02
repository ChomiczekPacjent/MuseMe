import SwiftUI

struct WizardStep1: View {
    @Binding var profileData: ProfileData
    @State private var selectedGender: String? = nil

    var body: some View {
        VStack {
            SegmentedProgressBar(currentStep: 2, totalSteps: 6)
                .padding([.horizontal, .top])
            
            Spacer()
            
            Text("What is your gender?")
                .font(.title)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding()
            
            HStack(spacing: 20) {
                Button(action: {
                    selectedGender = "Female"
                    profileData.gender = "Female"
                }) {
                    VStack {
                        Image("woman")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 80)
                        
                        Text("Female")
                            .font(.headline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(selectedGender == "Female" ? Color.white : Color.gray)
                    .cornerRadius(8)
                    .foregroundColor(selectedGender == "Female" ? .black : .white)
                }
                
                Button(action: {
                    selectedGender = "Male"
                    profileData.gender = "Male"
                }) {
                    VStack {
                        Image("man")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 80)
                        
                        Text("Male")
                            .font(.headline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(selectedGender == "Male" ? Color.white : Color.gray)
                    .cornerRadius(8)
                    .foregroundColor(selectedGender == "Male" ? .black : .white)
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            HStack {
                NavigationLink(destination: MainContainerView()) {
                    Text("Skip")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray)
                        .cornerRadius(8)
                }
                
                NavigationLink(destination: WizardStep2(profileData: $profileData)) {
                    Text("Next")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.purple)
                        .cornerRadius(8)
                }
                .disabled(selectedGender == nil)
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
                    .ignoresSafeArea()
                    .offset(x: -50)
                
                Color.black.opacity(0.4)
            }
        )
        .navigationBarHidden(true)
        .onAppear {
            selectedGender = profileData.gender.isEmpty ? nil : profileData.gender
        }
    }
}
