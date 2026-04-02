import Foundation

struct User: Identifiable, Codable {
    let id: String
    let fullName: String
    let email: String
    var didCompleteWizard: Bool?
    var provider: String?
    var spotifyAccessToken: String?
    var profileImageURL: String?

    
    var profile: ProfileData?

    var initials: String {
        let formatter = PersonNameComponentsFormatter()
        if let components = formatter.personNameComponents(from: fullName) {
            formatter.style = .abbreviated
            return formatter.string(from: components)
        }
        return ""
    }
}
