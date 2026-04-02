import SwiftUI

struct WizardContainerView: View {
    @State var profileData: ProfileData
    
    var body: some View {
        NavigationStack {
            WizardStep0(profileData: $profileData)
        }
    }
}

struct WizardContainerView_Previews: PreviewProvider {
    static var previews: some View {
        WizardContainerView(
            profileData: ProfileData(
                id: "",
                gender: "",
                age: 22,
                birthDate: Date(),
                height: 150,
                weight: 50,
                disease: "",
                genre: "",
                artist: ""
            )
        )
    }
}
