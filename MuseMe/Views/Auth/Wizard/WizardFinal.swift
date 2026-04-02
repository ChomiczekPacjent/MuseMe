import SwiftUI
import FirebaseFirestore

@MainActor
struct WizardFinal: View {
    @Environment(\.dismiss) var dismiss
    @Binding var profileData: ProfileData
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var isSaving = false

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    var body: some View {
        VStack {
            SegmentedProgressBar(currentStep: 6, totalSteps: 6)
                .padding([.horizontal, .top])
            
            Spacer()
            
            Text("Summary")
                .font(.title)
                .foregroundColor(.white)
                .padding(.bottom, 10)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Gender: \(profileData.gender.isEmpty ? "Not specified" : profileData.gender)")
                    .foregroundColor(.white)
                
                Text("Date of birth: \(WizardFinal.dateFormatter.string(from: profileData.birthDate))")
                    .foregroundColor(.white)
                
                Text("Height: \(profileData.height == 0 ? "Not specified" : String(Int(profileData.height)))")
                    .foregroundColor(.white)
                
                Text("Weight: \(profileData.weight == 0 ? "Not specified" : String(Int(profileData.weight)))")
                    .foregroundColor(.white)
                
                Text("Disease: \(profileData.disease.isEmpty ? "Not specified" : profileData.disease)")
                    .foregroundColor(.white)
                
                Text("Genre: \(profileData.genre.isEmpty ? "Not specified" : profileData.genre)")
                    .foregroundColor(.white)
            }
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
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
                
                Button(action: {
                    Task {
                        isSaving = true
                        
                        do {
                            try await authViewModel.saveProfileData(profileData)
                            
                            if let uid = authViewModel.userSession?.uid {
                                let data: [String: Bool] = ["didCompleteWizard": true]
                                try await Firestore.firestore()
                                    .collection("users")
                                    .document(uid)
                                    .updateData(data)
                            }

                            SessionManager.shared.didCompleteWizard = true
                            UserDefaults.standard.set(true, forKey: "didCompleteWizard")
                            
                            dismiss()
                        } catch {
                            print("Error saving profile data: \(error.localizedDescription)")
                        }
                        
                        isSaving = false
                    }
                }) {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .cornerRadius(8)
                    } else {
                        Text("Finish")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.purple)
                            .cornerRadius(8)
                    }
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
                    .ignoresSafeArea()
            }
        )
        .navigationBarHidden(true)
    }
}

struct WizardFinal_Previews: PreviewProvider {
    @State static var sampleProfile = ProfileData(
        id: "sample",
        gender: "Female",
        age: 22,
        birthDate: Date(),
        height: 170,
        weight: 60,
        disease: "",
        genre: "Rock",
        artist: "Queen"
    )

    static var previews: some View {
        WizardFinal(profileData: $sampleProfile)
            .environmentObject(AuthViewModel())
    }
}
