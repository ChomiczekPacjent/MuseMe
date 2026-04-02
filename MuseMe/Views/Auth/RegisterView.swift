import SwiftUI

struct RegisterView: View {
    @State private var email = ""
    @State private var fullName = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: AuthViewModel

    var body: some View {
        VStack {
            Image("finallogo")
                .resizable()
                .scaledToFit()
                .frame(height: 80)
            
            Spacer().frame(height: 25)
            
            Text("Sign up for MuseMe!")
                .font(.title)
                .foregroundColor(.white)
            
            Spacer().frame(height: 50)
            
            VStack(spacing: 24) {
                InputView(text: $email,
                          title: "Email address",
                          placeholder: "MuseMe@gmail.com")
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                
                InputView(text: $fullName,
                          title: "Name",
                          placeholder: "Enter your name")
                    .autocapitalization(.none)
                
                InputView(text: $password,
                          title: "Password",
                          placeholder: "Enter your password",
                          isSecureField: true)
                
                InputView(text: $confirmPassword,
                          title: "Confirm password",
                          placeholder: "Re-enter your password",
                          isSecureField: true)
            }
            .padding(.horizontal)
            .padding(.top, 12)
            
            Button {
                Task {
                    // Sprawdzamy, czy oba hasła są takie same
                    guard password == confirmPassword else {
                        print("Hasła nie są identyczne!")
                        return
                    }
                    do {
                        try await viewModel.createUser(
                            withEmail: email,
                            password: password,
                            fullName: fullName
                        )
                    } catch {
                        print("Błąd rejestracji: \(error)")
                    }
                }
            } label: {
                HStack {
                    Text("Sign up")
                        .fontWeight(.semibold)
                    Image(systemName: "music.note")
                }
                .foregroundColor(.black)
                .frame(width: UIScreen.main.bounds.width - 32, height: 48)
            }
            .background(Color.purple)
            .cornerRadius(10)
            .padding(.top, 24)
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                HStack(spacing: 3) {
                    Text("Already have an account?")
                        .foregroundColor(.white)
                    Text("Log in to MuseMe")
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

#Preview {
    RegisterView()
        .environmentObject(AuthViewModel())
}
