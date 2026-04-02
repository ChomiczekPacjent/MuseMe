import Foundation
import SpotifyiOS
import Combine

extension Notification.Name {
    static let spotifyLoginSuccess = Notification.Name("spotifyLoginSuccess")
}

class SpotifyAuthManager: NSObject, ObservableObject, SPTSessionManagerDelegate {
    static let shared = SpotifyAuthManager()

    private(set) var configuration: SPTConfiguration = {
        let config = SPTConfiguration(clientID: spotifyClientId, redirectURL: redirectUri)
        config.tokenSwapURL = URL(string: "http://192.168.1.105:1234/swap")
        config.tokenRefreshURL = URL(string: "http://192.168.1.105:1234/refresh")
        return config
    }()

    private(set) var sessionManager: SPTSessionManager?
    private(set) var appRemote: SPTAppRemote?

    var accessToken: String? {
        didSet {
            UserDefaults.standard.set(accessToken, forKey: accessTokenKey)
        }
    }

    var refreshToken: String?

    @Published var spotifyUser: SpotifyUser?
    @Published var userPlaylists: [SpotifyPlaylist] = []
    


    override init() {
        super.init()
        self.sessionManager = SPTSessionManager(configuration: configuration, delegate: self)
    }

    func initiateSession() {
        sessionManager?.initiateSession(with: scopes, options: [], campaign: nil)
    }

    func handleOpenURL(url: URL) {
        print("SpotifyAuthManager - handleOpenURL: \(url.absoluteString)")
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            print("Couldn't extract code from URL")
            return
        }
        exchangeCodeForToken(code: code)
    }

    private func exchangeCodeForToken(code: String) {
        let url = URL(string: "https://accounts.spotify.com/api/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let authString = "\(spotifyClientId):\(spotifyClientSecretKey)"
        let base64Auth = Data(authString.utf8).base64EncodedString()
        request.setValue("Basic \(base64Auth)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyParams = [
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": redirectUri.absoluteString
        ]

        request.httpBody = bodyParams
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print("Error exchanging code: \(error.localizedDescription)")
                return
            }

            guard let data else {
                print("No data in exchangeCodeForToken")
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let token = json["access_token"] as? String {
                    DispatchQueue.main.async {
                        self.accessToken = token
                        print("Access token set: \(token)")
                        self.fetchSpotifyUserInfo()
                        self.fetchUserPlaylists()
                        self.fetchLikedSongsAsPlaylist()
                        NotificationCenter.default.post(name: .spotifyLoginSuccess, object: nil)
                    }
                } else {
                    print("Failed to extract token from JSON")
                }
            } catch {
                print("JSON decode error: \(error.localizedDescription)")
            }
        }.resume()
    }

    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        accessToken = session.accessToken
        print(" Spotify session started, token: \(session.accessToken)")
        let config = SPTConfiguration(clientID: spotifyClientId, redirectURL: redirectUri)
        appRemote = SPTAppRemote(configuration: config, logLevel: .debug)
        appRemote?.connectionParameters.accessToken = session.accessToken
        appRemote?.connect()
    }

    func sessionManager(manager: SPTSessionManager, didFailWith error: Error) {
        print(" SpotifyAuthManager - Auth error: \(error.localizedDescription)")
    }

    func sessionManager(manager: SPTSessionManager, didRenew session: SPTSession) {
        accessToken = session.accessToken
        print(" Token renewed: \(session.accessToken)")
    }

    func fetchSpotifyUserInfo() {
        guard let accessToken else {
            print(" No access token to fetch user info")
            return
        }

        let url = URL(string: "https://api.spotify.com/v1/me")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print(" Failed to fetch user info: \(error.localizedDescription)")
                return
            }

            guard let data else {
                print(" Empty data when fetching user info")
                return
            }

            do {
                let user = try JSONDecoder().decode(SpotifyUser.self, from: data)
                DispatchQueue.main.async {
                    self.spotifyUser = user
                    print("User loaded: \(user.display_name)")
                }
            } catch {
                print("Failed to decode user: \(error.localizedDescription)")
            }
        }.resume()
    }

    func fetchUserPlaylists() {
        guard let accessToken else {
            print("No access token to fetch playlists")
            return
        }

        let url = URL(string: "https://api.spotify.com/v1/me/playlists")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print("Failed to fetch playlists: \(error.localizedDescription)")
                return
            }

            guard let data else {
                print("Empty playlist data")
                return
            }

            do {
                let response = try JSONDecoder().decode(SpotifyPlaylistResponse.self, from: data)
                DispatchQueue.main.async {
                    let newPlaylists = response.items.filter { $0.id != "liked-songs" }
                    self.userPlaylists += newPlaylists.filter { !self.userPlaylists.map(\.id).contains($0.id) }
                    print("Loaded \(newPlaylists.count) playlists (+ any existing ones)")
                }
            } catch {
                print("Failed to decode playlists: \(error.localizedDescription)")
            }
        }.resume()
    }

    func fetchLikedSongsAsPlaylist() {
        guard let accessToken else {
            print("No access token to fetch liked songs")
            return
        }

        let url = URL(string: "https://api.spotify.com/v1/me/tracks?limit=1")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print("Failed to fetch liked songs: \(error.localizedDescription)")
                return
            }

            guard let data else {
                print(" Empty liked songs data")
                return
            }

            do {
                let response = try JSONDecoder().decode(LikedTracksResponse.self, from: data)
                let firstTrack = response.items.first?.track
                let imageURL = firstTrack?.album.images.first?.url

                let likedPlaylist = SpotifyPlaylist(
                    id: "liked-songs",
                    name: "Liked Songs",
                    images: imageURL != nil ? [SpotifyImage(url: imageURL!)] : [],
                    uri: "spotify:collection:tracks"
                )

                DispatchQueue.main.async {
                    if !self.userPlaylists.contains(where: { $0.id == "liked-songs" }) {
                        self.userPlaylists.insert(likedPlaylist, at: 0)
                    }
                }

            } catch {
                print(" Failed to decode liked songs: \(error.localizedDescription)")
            }
        }.resume()
    }


    func refreshAccessToken(completion: @escaping (String?) -> Void) {
        guard let refreshToken else {
            completion(nil)
            return
        }

        let url = URL(string: "https://accounts.spotify.com/api/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let authString = "\(spotifyClientId):\(spotifyClientSecretKey)"
        let base64Auth = Data(authString.utf8).base64EncodedString()
        request.setValue("Basic \(base64Auth)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyParams = [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken
        ]

        request.httpBody = bodyParams
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print(" Refresh error: \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let data else {
                completion(nil)
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let newToken = json["access_token"] as? String {
                    self.accessToken = newToken
                    completion(newToken)
                } else {
                    completion(nil)
                }
            } catch {
                print(" Error decoding refresh token: \(error.localizedDescription)")
                completion(nil)
            }
        }.resume()
    }
}

// Models

struct SpotifyUser: Codable {
    let id: String
    let display_name: String
    let email: String
    let images: [SpotifyImage]?

    var avatarURL: String? {
        images?.first?.url
    }
}

struct SpotifyPlaylistResponse: Codable {
    let items: [SpotifyPlaylist]
}

struct SpotifyPlaylist: Codable, Identifiable {
    let id: String
    let name: String
    let images: [SpotifyImage]?
    let uri: String?
}

struct SpotifyImage: Codable {
    let url: String
}


struct LikedTracksResponse: Codable {
    let items: [LikedTrackItem]
}

struct LikedTrackItem: Codable {
    let track: SpotifyTrack
}

struct SpotifyTrack: Codable {
    let album: SpotifyAlbum
}

struct SpotifyAlbum: Codable {
    let images: [SpotifyImage]
}
