import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @EnvironmentObject var viewModel:  AuthViewModel
    
    var body: some View {
        NavigationStack {
            VStack {
                
                Image("finallogo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 80)
                
                Spacer().frame(height: 25)
                
                Text("Log in to MuseMe!")
                    .font(.title)
                    .foregroundColor(.white)
                
                Spacer().frame(height: 50)
                
                VStack(spacing: 24) {
                    InputView(
                        text: $email,
                        title: "Email",
                        placeholder: "MuseMe@gmail.com"
                    )
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    
                    InputView(
                        text: $password,
                        title: "Password",
                        placeholder: "Enter your password",
                        isSecureField: true
                    )
                }
                .padding(.horizontal)
                .padding(.top, 12)
                
                Button {
                    Task{
                        try await viewModel.signIn(withEmail: email, password: password)
                    }
                } label: {
                    HStack {
                        Text("Log in")
                            .fontWeight(.semibold)
                        Image(systemName: "music.note")
                    }
                    .foregroundColor(.black)
                    .frame(width: UIScreen.main.bounds.width - 32, height: 50)
                }
                .background(Color(.systemPurple))
                .cornerRadius(10)
                .padding(.top)
                
                
                Spacer().frame(height: 20)
                
                Text("Or")
                    .foregroundColor(.white)
                

                
                Spacer()
                
                NavigationLink {
                    RegisterView()
                        .navigationBarBackButtonHidden(true)
                } label: {
                    HStack(spacing: 3) {
                        Text("Don't have an account?")
                            .foregroundColor(.white)
                        Text("Sign up for MuseMe")
                            .fontWeight(.bold)
                            .foregroundColor(.purple)
                    }
                    .font(.system(size: 14))
                }
            }
            .padding()
            .background(Color.black.ignoresSafeArea())
        }
    }
}

#Preview {
    LoginView()
}
