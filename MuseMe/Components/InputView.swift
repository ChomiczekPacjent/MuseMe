import SwiftUI

struct InputView: View {
    @Binding var text: String
    let title: String
    let placeholder: String
    var isSecureField: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Etykieta nad polem
            Text(title)
                .foregroundColor(.white)
                .fontWeight(.semibold)
                .font(.footnote)
            
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundColor(.gray)  
                        .padding(10)
                }
                if isSecureField {
                    SecureField("", text: $text)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .padding(10)
                } else {
                    TextField("", text: $text)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .padding(10)
                }
            }
            .background(Color.black)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white, lineWidth: 1)  // Biała ramka
            )
        }
    }
}

#Preview {
    InputView(text: .constant(""), title: "Email", placeholder: "MuseMe@gmail.com")
}
