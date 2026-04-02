import Foundation
import FirebaseAuth
import Firebase
import FirebaseFirestore
import FirebaseFunctions

@MainActor
class AuthViewModel: ObservableObject {

    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: User?
    @Published var spotifyAccessToken: String?
    
    @Published var profileData = ProfileData(
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

    private lazy var functions = Functions.functions()

    init() {
        self.userSession = Auth.auth().currentUser
        Task {
            await fetchUser()
            await fetchProfileData()
        }
    }

    @MainActor
    func signIn(withEmail email: String, password: String) async throws {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        self.userSession = result.user
        await fetchUser()
        await fetchProfileData()
        SessionManager.shared.isLoggedIn = true
    }

    func createUser(withEmail email: String, password: String, fullName: String) async throws {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            self.userSession = result.user

            let user = User(id: result.user.uid, fullName: fullName, email: email)

            let userData: [String: Any] = [
                "id": user.id,
                "fullName": user.fullName,
                "email": user.email,
                "provider": "email",
                "didCompleteWizard": false
            ]

            try await Firestore.firestore().collection("users").document(user.id).setData(userData)

            self.profileData = ProfileData(
                id: user.id,
                gender: "",
                age: 22,
                birthDate: Date(),
                height: 150,
                weight: 50,
                disease: "",
                genre: "",
                artist: ""
            )

            await fetchUser()

            SessionManager.shared.isLoggedIn = true
            SessionManager.shared.didCompleteWizard = false
        } catch {
            print("Error creating user: \(error.localizedDescription)")
            throw error
        }
    }

    func updateSpotifyToken(_ accessToken: String, userID: String?, spotifyID: String?) async {
        guard let userID = userID ?? userSession?.uid else {
            print("Brak user ID przy zapisie Spotify token")
            return
        }

        let data: [String: Any] = [
            "spotifyAccessToken": accessToken,
            "spotifyID": spotifyID ?? ""
        ]

        do {
            try await Firestore.firestore().collection("users").document(userID).setData(data, merge: true)
            print("Spotify token zapisany dla user: \(userID)")
            self.spotifyAccessToken = accessToken
        } catch {
            print("Błąd zapisu Spotify token: \(error.localizedDescription)")
        }
    }

    func saveProfileData(_ profileData: ProfileData) async throws {
        guard let uid = self.userSession?.uid else {
            print("No user session – cannot save profile data.")
            return
        }

        let data: [String: Any] = [
            "id": uid,
            "gender": profileData.gender,
            "birth": profileData.birthDate,
            "height": profileData.height,
            "weight": profileData.weight,
            "disease": profileData.disease,
            "genre": profileData.genre,
            "artist": profileData.artist
        ]

        do {
            try await Firestore.firestore()
                .collection("user additional data")
                .document(uid)
                .setData(data)

            self.profileData = profileData
            print("Profile data saved successfully for userID: \(uid)")
        } catch {
            print("Error saving profile data: \(error.localizedDescription)")
            throw error
        }
    }

    func fetchProfileData() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        do {
            let snapshot = try await Firestore.firestore()
                .collection("user additional data")
                .document(uid)
                .getDocument()

            guard let data = snapshot.data() else {
                print("Brak dodatkowych danych profilu.")
                return
            }

            let gender = data["gender"] as? String ?? ""
            let birthDate = (data["birth"] as? Timestamp)?.dateValue() ?? Date()
            let height = data["height"] as? Double ?? 150
            let weight = data["weight"] as? Double ?? 50
            let disease = data["disease"] as? String ?? ""
            let genre = data["genre"] as? String ?? ""
            let artist = data["artist"] as? String ?? ""

            self.profileData = ProfileData(
                id: uid,
                gender: gender,
                age: 22,
                birthDate: birthDate,
                height: height,
                weight: weight,
                disease: disease,
                genre: genre,
                artist: artist
            )

            print("Pobrano profileData: \(self.profileData)")
        } catch {
            print("Błąd pobierania profileData: \(error.localizedDescription)")
        }
    }

    func fetchUser() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        do {
            let snapshot = try await Firestore.firestore()
                .collection("users")
                .document(uid)
                .getDocument()

            self.currentUser = try snapshot.data(as: User.self)
            print("Pobrano użytkownika: \(String(describing: self.currentUser))")

            if let data = snapshot.data(), let didComplete = data["didCompleteWizard"] as? Bool {
                SessionManager.shared.didCompleteWizard = didComplete
            } else {
                SessionManager.shared.didCompleteWizard = false
            }
        } catch {
            print("Błąd pobierania użytkownika: \(error.localizedDescription)")
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            self.userSession = nil
            self.currentUser = nil
            self.spotifyAccessToken = nil

            self.profileData = ProfileData(
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

            SessionManager.shared.isLoggedIn = false
            print("Wylogowano użytkownika")
        } catch {
            print("Błąd wylogowania: \(error.localizedDescription)")
        }
    }

    func deleteAccount() {
        guard let currentUser = Auth.auth().currentUser else { return }
        currentUser.delete { error in
            if let error = error {
                print("Błąd podczas usuwania konta: \(error.localizedDescription)")
            } else {
                self.userSession = nil
                self.currentUser = nil
                print("Konto usunięte")
            }
        }
    }
}
