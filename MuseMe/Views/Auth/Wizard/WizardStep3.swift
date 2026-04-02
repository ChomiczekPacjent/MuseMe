import SwiftUI

struct WizardStep3: View {
    @Environment(\.dismiss) var dismiss
    @Binding var profileData: ProfileData

    let diseases = ["Heart Disease", "Hypertension", "Diabetes", "Asthma", "Chronic Obstructive Pulmonary Disease (COPD)", "Other", "None"]
    
    @State private var selectedDiseases: Set<String> = []

    var body: some View {
        VStack {
            SegmentedProgressBar(currentStep: 4, totalSteps: 6)
                .padding([.horizontal, .top])
            

            Text("Do you have any chronic diseases?")
                .font(.title)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding()

            VStack(alignment: .leading, spacing: 10) {
                ForEach(diseases, id: \.self) { disease in
                    Toggle(disease, isOn: Binding(
                        get: { selectedDiseases.contains(disease) },
                        set: { isSelected in
                            if isSelected {
                                selectedDiseases.insert(disease)
                            } else {
                                selectedDiseases.remove(disease)
                            }
                            profileData.disease = selectedDiseases.joined(separator: ", ")
                        }
                    ))
                    .toggleStyle(SwitchToggleStyle(tint: .purple))
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            
            Spacer()

            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Text("Back")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray)
                        .cornerRadius(8)
                }
                
                NavigationLink(destination: WizardStep4(profileData: $profileData)) {
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
                    .offset(x: +50)
                    .ignoresSafeArea()
            }
        )          .navigationBarHidden(true)
        .onAppear {
            selectedDiseases = Set(profileData.disease.split(separator: ", ").map { String($0) })
        }
    }
}
