import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    
    @State private var showMyData = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    if let user = viewModel.currentUser {
                        HStack(spacing: 16) {
                            Text(user.initials)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(width: 72, height: 72)
                                .background(Color.gray)
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.fullName)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Text(user.email)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                    
                    VStack(spacing: 1) {
                        ProfileOption(icon: "person.fill", title: "My Data", color: .white) {
                            showMyData = true
                        }
                        
                        ProfileOption(icon: "arrow.left.circle", title: "Sign out", color: .red) {
                            viewModel.signOut()
                        }
                    }
                    .background(Color(white: 0.1))
                    .cornerRadius(0)
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical)
            }
            .background(Color.black.ignoresSafeArea())
            .sheet(isPresented: $showMyData) {
                WizardContainerView(profileData: viewModel.profileData)
                    .environmentObject(viewModel)
            }
        }
    }
}

struct ProfileOption: View {
    let icon: String
    let title: String
    var rightText: String? = nil
    var color: Color = .white
    var action: (() -> Void)? = nil

    var body: some View {
        Button(action: {
            action?()
        }) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 24)
                    .foregroundColor(color)

                Text(title)
                    .foregroundColor(.white)

                Spacer()

                if let rightText {
                    Text(rightText)
                        .foregroundColor(.gray)
                        .font(.subheadline)
                }

                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}
