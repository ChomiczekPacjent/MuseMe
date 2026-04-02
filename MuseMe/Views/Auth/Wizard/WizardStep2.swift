import SwiftUI

struct WizardStep2: View {
    @Environment(\.dismiss) var dismiss
    @Binding var profileData: ProfileData
    var textColor: Color {
        .white
    }

    var calculatedMinWeight: Double {
        guard profileData.height >= 120 else { return 30 }
        let ratio = (profileData.height - 120) / (220 - 120)
        return 30 + ratio * (70 - 30)
    }
    
    var calculatedMaxWeight: Double {
        guard profileData.height >= 100 else { return 150 }
        guard profileData.height <= 220 else { return 200 }
        
        let ratio = (profileData.height - 100) / (220 - 100)
        return 150 + ratio * (200 - 150)
    }
    
   
    
    var body: some View {
        VStack {
            SegmentedProgressBar(currentStep: 3, totalSteps: 6)
                .padding([.horizontal, .top])
            
            Spacer().frame(height: 40)
            
            VStack(alignment: .leading, spacing: 20) {
               
                let minDate = Calendar.current.date(byAdding: .year, value: -140, to: Date())!
                let maxDate = Date()
                
                Text("Your Birth Date:")
                    .font(.headline)
                    .foregroundColor(textColor)
                DatePicker(
                    "Select your birth date",
                    selection: $profileData.birthDate,
                    in: minDate...maxDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(WheelDatePickerStyle())
                .labelsHidden()
                .environment(\.colorScheme, .dark)
                
                Spacer().frame(height: 20)
                
                // Wzrost
                Text("Your Height (cm):")
                    .font(.headline)
                    .foregroundColor(textColor)
                Text("\(Int(profileData.height)) cm")
                    .foregroundColor(textColor)
                    .padding(.bottom, 4)
                Slider(value: $profileData.height, in: 100...220, step: 1)
                    .accentColor(.purple)
                    .onChange(of: profileData.height) { newHeight, transaction in
                        if profileData.weight < calculatedMinWeight {
                            profileData.weight = calculatedMinWeight
                        } else if profileData.weight > calculatedMaxWeight {
                            profileData.weight = calculatedMaxWeight
                        }
                    }


                
                Spacer().frame(height: 20)
                
                // Waga
                Text("Your Weight (kg):")
                    .font(.headline)
                    .foregroundColor(textColor)
                Text("\(Int(profileData.weight)) kg")
                    .foregroundColor(textColor)
                    .padding(.bottom, 4)
                Slider(
                    value: $profileData.weight,
                    in: calculatedMinWeight...calculatedMaxWeight,
                    step: 1
                )
                .accentColor(.purple)
            }
            .padding(.horizontal)
            
            Spacer()
            
            HStack {
                Button(action: { dismiss() }) {
                    Text("Back")
                        .foregroundColor(textColor)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray)
                        .cornerRadius(8)
                }
                
                NavigationLink(destination: WizardStep3(profileData: $profileData)) {
                    Text("Next")
                        .foregroundColor(textColor)
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
                    .ignoresSafeArea()
                Color.black.opacity(0.4)
            }
        )          .navigationBarHidden(true)
    }
}
