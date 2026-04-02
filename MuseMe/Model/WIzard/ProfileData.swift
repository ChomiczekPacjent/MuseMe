import Foundation

struct ProfileData: Identifiable, Codable {
    let id: String
    var gender: String
    var age: Int
    var birthDate: Date = Date() 
    var height: Double = 150
    var weight: Double = 50
    var disease: String
    var genre: String
    var artist: String
}
