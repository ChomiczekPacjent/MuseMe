import Foundation
import SwiftUI
import Combine
import SpotifyiOS


struct SpotifySong {
    let name: String
    let uri: String
    let artist: String
    var bpm: Double?
}


extension Color {
    static let spotifyBackground = Color(red: 18/255, green: 18/255, blue: 18/255)
}


final class SpotifyPlayerViewModel: NSObject, ObservableObject {
    static let shared = SpotifyPlayerViewModel()


    private var likedTracks: [SpotifySong] = []
    private var isLoadingLikedTracks: Bool = false
    private var likedTracksPreloadCompletions: [([SpotifySong]) -> Void] = []
    private let museMePlaylistId = "3FdZ6psubs89K11C2DbQkt"
    private var museMeTracks: [SpotifySong] = []
    private var isLoadingMuseMeTracks = false

    private var trackBPMCache: [String: Double] = [:]
    private var lastBPMCheckedURI: String? = nil

    private var bpmPreloadQueue: [SpotifySong] = []
    private var isPreloadingBPMQueue: Bool = false
    private let maxSongsForInitialBPMPreload = 40

    private var lastAutoSwitchDate: Date = .distantPast
    private var lastTargetBPM: Int? = nil


    private var inactivityTimer: Timer?
    /// Po ilu sekundach bez akcji użytkownika rozłączamy i czyścimy token
    private let inactivityTimeout: TimeInterval = 10 * 60  // 10 minut


    @Published var trackName: String = "No track playing"
    @Published var artwork: UIImage? = nil
    @Published var isPaused: Bool = true
    @Published var isConnected: Bool = false
    @Published var currentPosition: TimeInterval = 0
    @Published var trackDuration: TimeInterval = 0
    @Published var trackBPM: Double? = nil
    @Published var isCurrentTrackLiked: Bool = false
    @Published var trackArtist: String = ""
    @Published var shouldShowConnectView: Bool = false
    @Published var isPlaying: Bool = false

    private var connectFallbackTimer: Timer?
    var currentlyPlayingURI: String? = nil


    var accessToken: String? {
        didSet {
            if let token = accessToken {
                UserDefaults.standard.set(token, forKey: accessTokenKey)
            } else {
                UserDefaults.standard.removeObject(forKey: accessTokenKey)
            }
        }
    }

    private(set) var appRemote: SPTAppRemote
    private var lastPlayerState: SPTAppRemotePlayerState?
    private var progressTimer: AnyCancellable?


    private override init() {
        let config = SPTConfiguration(clientID: spotifyClientId, redirectURL: redirectUri)
        config.tokenSwapURL = URL(string: "http://localhost:1234/swap")
        config.tokenRefreshURL = URL(string: "http://localhost:1234/refresh")

        self.appRemote = SPTAppRemote(configuration: config, logLevel: .debug)
        super.init()
        self.appRemote.delegate = self
        self.accessToken = UserDefaults.standard.string(forKey: accessTokenKey)
    }

    private func resetInactivityTimer() {
        inactivityTimer?.invalidate()
        inactivityTimer = Timer.scheduledTimer(withTimeInterval: inactivityTimeout,
                                               repeats: false) { [weak self] _ in
            self?.handleInactivityTimeout()
        }
    }

    private func cancelInactivityTimer() {
        inactivityTimer?.invalidate()
        inactivityTimer = nil
    }

    private func handleInactivityTimeout() {
        DispatchQueue.main.async {
            print("Inactivity timeout – disconnecting from Spotify and clearing token")
            self.appRemote.disconnect()
            self.stopProgressTimer()
            self.lastPlayerState = nil

            self.accessToken = nil

            self.isConnected = false
            self.isPaused = true
            self.currentPosition = 0
            self.shouldShowConnectView = true
        }
    }


    private func fetchLikedTracksBasic(completion: @escaping ([SpotifySong]) -> Void) {
        guard let token = self.accessToken else {
            print("rak access tokena – fetchLikedTracksBasic przerwane")
            completion([])
            return
        }

        let limit = 50
        var allTracks: [SpotifySong] = []

        func loadPage(offset: Int) {
            guard let url = URL(string: "https://api.spotify.com/v1/me/tracks?limit=\(limit)&offset=\(offset)") else {
                DispatchQueue.main.async { completion(allTracks) }
                return
            }

            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            URLSession.shared.dataTask(with: request) { data, _, error in
                if let error = error {
                    print("Błąd pobierania polubionych utworów: \(error.localizedDescription)")
                    DispatchQueue.main.async { completion(allTracks) }
                    return
                }

                guard let data = data else {
                    print("Brak danych z /me/tracks")
                    DispatchQueue.main.async { completion(allTracks) }
                    return
                }

                do {
                    guard
                        let json  = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                        let items = json["items"] as? [[String: Any]]
                    else {
                        print("Nieoczekiwany JSON z /me/tracks")
                        DispatchQueue.main.async { completion(allTracks) }
                        return
                    }

                    print(" /me/tracks page offset=\(offset) items.count = \(items.count)")

                    let pageTracks: [SpotifySong] = items.compactMap { item in
                        guard let trackDict = item["track"] as? [String: Any],
                              let name       = trackDict["name"] as? String,
                              let uri        = trackDict["uri"]  as? String
                        else {
                            return nil
                        }

                        let artistsArray = trackDict["artists"] as? [[String: Any]]
                        let artistName = (artistsArray?.first?["name"] as? String) ?? "Unknown Artist"

                        return SpotifySong(
                            name: name,
                            uri: uri,
                            artist: artistName,
                            bpm: nil
                        )
                    }

                    allTracks.append(contentsOf: pageTracks)

                    if items.count < limit {
                        DispatchQueue.main.async { completion(allTracks) }
                    } else {
                        loadPage(offset: offset + limit)
                    }
                } catch {
                    print("Błąd parsowania JSON: \(error.localizedDescription)")
                    DispatchQueue.main.async { completion(allTracks) }
                }
            }.resume()
        }

        loadPage(offset: 0)
    }

    private func fetchMuseMeTracksBasic(completion: @escaping ([SpotifySong]) -> Void) {
        guard let token = self.accessToken else {
            print("Brak access tokena – fetchMuseMeTracksBasic przerwane")
            completion([])
            return
        }

        let limit = 100
        var allTracks: [SpotifySong] = []

        func loadPage(offset: Int) {
            guard let url = URL(string: "https://api.spotify.com/v1/playlists/\(museMePlaylistId)/tracks?limit=\(limit)&offset=\(offset)") else {
                DispatchQueue.main.async { completion(allTracks) }
                return
            }

            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            URLSession.shared.dataTask(with: request) { data, _, error in
                if let error = error {
                    print("Błąd pobierania MuseMe tracks: \(error.localizedDescription)")
                    DispatchQueue.main.async { completion(allTracks) }
                    return
                }

                guard let data = data else {
                    print("Brak danych z playlist tracks")
                    DispatchQueue.main.async { completion(allTracks) }
                    return
                }

                do {
                    guard
                        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                        let items = json["items"] as? [[String: Any]]
                    else {
                        print("Nieoczekiwany JSON z playlist tracks")
                        DispatchQueue.main.async { completion(allTracks) }
                        return
                    }

                    print("MuseMe playlist page offset=\(offset) items.count=\(items.count)")

                    let pageTracks: [SpotifySong] = items.compactMap { item in
                        guard let trackDict = item["track"] as? [String: Any],
                              let name = trackDict["name"] as? String,
                              let uri  = trackDict["uri"] as? String
                        else { return nil }

                        let artistsArray = trackDict["artists"] as? [[String: Any]]
                        let artistName = (artistsArray?.first?["name"] as? String) ?? "Unknown Artist"

                        return SpotifySong(name: name, uri: uri, artist: artistName, bpm: nil)
                    }

                    allTracks.append(contentsOf: pageTracks)

                    if items.count < limit {
                        DispatchQueue.main.async { completion(allTracks) }
                    } else {
                        loadPage(offset: offset + limit)
                    }
                } catch {
                    print("Błąd parsowania JSON playlist tracks: \(error.localizedDescription)")
                    DispatchQueue.main.async { completion(allTracks) }
                }
            }.resume()
        }

        loadPage(offset: 0)
    }
    
    func preloadMuseMeTracks(completion: (() -> Void)? = nil) {
        if !museMeTracks.isEmpty { completion?(); return }
        if isLoadingMuseMeTracks { return }

        isLoadingMuseMeTracks = true
        fetchMuseMeTracksBasic { tracks in
            DispatchQueue.main.async {
                self.isLoadingMuseMeTracks = false
                self.museMeTracks = tracks
                print("MuseMeTracks załadowane: \(tracks.count)")

                self.bpmPreloadQueue = Array(tracks.prefix(self.maxSongsForInitialBPMPreload))
                self.startBPMPreloadQueueForMuseMeIfNeeded()

                completion?()
            }
        }
    }

    private func updateBPMInMuseMeTracks(uri: String, bpm: Double) {
        if let idx = museMeTracks.firstIndex(where: { $0.uri == uri }) {
            museMeTracks[idx].bpm = bpm
        }
    }

    private func startBPMPreloadQueueForMuseMeIfNeeded() {
        guard !isPreloadingBPMQueue else { return }
        guard !bpmPreloadQueue.isEmpty else { return }
        isPreloadingBPMQueue = true

        func processNext() {
            if self.bpmPreloadQueue.isEmpty {
                self.isPreloadingBPMQueue = false
                print(" BPM preload (MuseMe) zakończony")
                return
            }

            let song = self.bpmPreloadQueue.removeFirst()

            if let cached = self.trackBPMCache[song.uri] {
                self.updateBPMInMuseMeTracks(uri: song.uri, bpm: cached)
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) { processNext() }
                return
            }

            GetSongBPMService.shared.fetchBPM(title: song.name, artist: song.artist) { [weak self] bpm in
                guard let self = self else { return }
                if let bpm = bpm {
                    self.trackBPMCache[song.uri] = bpm
                    self.updateBPMInMuseMeTracks(uri: song.uri, bpm: bpm)
                }
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) { processNext() }
            }
        }

        DispatchQueue.global().async { processNext() }
    }
    private func updateBPMInLikedTracks(uri: String, bpm: Double) {
        if let idx = likedTracks.firstIndex(where: { $0.uri == uri }) {
            likedTracks[idx].bpm = bpm
        }
    }

    private func startBPMPreloadQueueIfNeeded() {
        guard !isPreloadingBPMQueue else { return }
        guard !bpmPreloadQueue.isEmpty else { return }

        isPreloadingBPMQueue = true

        func processNext() {
            if self.bpmPreloadQueue.isEmpty {
                self.isPreloadingBPMQueue = false
                print(" BPM preload kolejki zakończony")
                return
            }

            let song = self.bpmPreloadQueue.removeFirst()

            if let cached = self.trackBPMCache[song.uri] {
                print("BPM preload z cache – \(song.name) = \(cached)")
                self.updateBPMInLikedTracks(uri: song.uri, bpm: cached)
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
                    processNext()
                }
                return
            }

            print("(preload) GetSongBPM dla: \(song.name) – \(song.artist)")

            GetSongBPMService.shared.fetchBPM(
                title: song.name,
                artist: song.artist
            ) { [weak self] bpm in
                guard let self = self else { return }

                if let bpm = bpm {
                    self.trackBPMCache[song.uri] = bpm
                    self.updateBPMInLikedTracks(uri: song.uri, bpm: bpm)
                    print("(preload) BPM = \(bpm) dla \(song.name)")
                } else {
                    print("(preload) brak BPM dla \(song.name)")
                }

                DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                    processNext()
                }
            }
        }

        DispatchQueue.global().async {
            processNext()
        }
    }

    func preloadLikedTracks(completion: (([SpotifySong]) -> Void)? = nil) {
        if !likedTracks.isEmpty {
            print("preloadLikedTracks – cache już istnieje: \(likedTracks.count) utworów")
            completion?(likedTracks)
            return
        }

        if isLoadingLikedTracks {
            print("preloadLikedTracks – ładowanie już trwa, dopisuję completion")
            if let completion = completion {
                likedTracksPreloadCompletions.append(completion)
            }
            return
        }

        isLoadingLikedTracks = true
        if let completion = completion {
            likedTracksPreloadCompletions.append(completion)
        }

        fetchLikedTracksBasic { tracks in
            DispatchQueue.main.async {
                self.isLoadingLikedTracks = false
                self.likedTracks = tracks
                print("LikedTracks załadowane: \(tracks.count) utworów (BPM liczymy tylko częściowo)")

                self.bpmPreloadQueue = Array(tracks.prefix(self.maxSongsForInitialBPMPreload))
                self.startBPMPreloadQueueIfNeeded()

                let completions = self.likedTracksPreloadCompletions
                self.likedTracksPreloadCompletions.removeAll()
                completions.forEach { $0(tracks) }
            }
        }
    }

    // MARK: - BPM z GetSongBPM dla aktualnego tracka

    private func resolveBPMUsingGetSongBPM(title: String, artist: String, uri: String) {
        // Najpierw cache
        if let cached = trackBPMCache[uri] {
            DispatchQueue.main.async {
                self.trackBPM = cached
            }
            print("trackBPM z cache: \(cached) dla \(title) – \(artist)")
            return
        }

        if lastBPMCheckedURI == uri {
            print("resolveBPMUsingGetSongBPM – BPM już pobierane dla \(uri), pomijam")
            return
        }
        lastBPMCheckedURI = uri

        GetSongBPMService.shared.fetchBPM(
            title: title,
            artist: artist
        ) { [weak self] bpm in
            guard let self = self else { return }

            if let bpm = bpm {
                self.trackBPMCache[uri] = bpm
                self.updateBPMInLikedTracks(uri: uri, bpm: bpm)
                self.updateBPMInMuseMeTracks(uri: uri, bpm: bpm)
                DispatchQueue.main.async {
                    self.trackBPM = bpm
                }
                print("trackBPM ustawione z GetSongBPM: \(bpm)")
            } else {
                print("GetSongBPM – brak BPM dla \(title) – \(artist)")
            }
        }
    }

    // MARK: - Start z Liked Songs

    func playFromLikedSongs() {
        resetInactivityTimer()

        let startPlayback: ([SpotifySong]) -> Void = { [weak self] tracks in
            guard let self = self else { return }
            guard let first = tracks.first else {
                print("Brak polubionych utworów – nie ma czego zagrać (bez fallbacku na playlistę)")
                return
            }
            print("Start z Liked Songs: \(first.name)")
            self.play(uri: first.uri)
        }

        if likedTracks.isEmpty {
            print("playFromLikedSongs – cache pusty, robię preload i zagram po zakończeniu")
            preloadLikedTracks(completion: startPlayback)
        } else {
            startPlayback(likedTracks)
        }
    }

    func playLikedSongsContextViaWebAPI() {
        resetInactivityTimer()

        guard let token = accessToken else {
            print("playLikedSongsContextViaWebAPI – brak accessTokenu")
            return
        }

        guard let url = URL(string: "https://api.spotify.com/v1/me/player/play") else {
            print("playLikedSongsContextViaWebAPI – zły URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "context_uri": "spotify:collection:tracks"
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                print("playLikedSongsContext error: \(error.localizedDescription)")
                return
            }

            if let http = response as? HTTPURLResponse {
                print("playLikedSongsContext status = \(http.statusCode)")
            }
        }.resume()
    }

    
    func playContextViaWebAPI(_ contextURI: String) {
        resetInactivityTimer()

        guard let token = accessToken else {
            print("playContextViaWebAPI – brak accessTokenu")
            return
        }

        guard let url = URL(string: "https://api.spotify.com/v1/me/player/play") else {
            print("playContextViaWebAPI – zły URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["context_uri": contextURI]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                print("playContextViaWebAPI error: \(error.localizedDescription)")
                return
            }
            if let http = response as? HTTPURLResponse {
                print("playContextViaWebAPI status=\(http.statusCode) context=\(contextURI)")
            }
        }.resume()
    }
    // MARK: - Connect / Disconnect

    func connect() {
        if let token = UserDefaults.standard.string(forKey: accessTokenKey) {
            self.accessToken = token
            appRemote.connectionParameters.accessToken = token
            print("SpotifyPlayerViewModel: Connecting with token \(token)")
            appRemote.connect()
        } else {
            print("No token available for connection.")
        }
    }

    func disconnect() {
        appRemote.disconnect()
        stopProgressTimer()
        cancelInactivityTimer()

        DispatchQueue.main.async {
            self.isConnected = false
            self.isPaused = true
            self.currentPosition = 0
        }
    }

    // MARK: - Playback Controls

    func togglePlayPause() {
        guard let playerAPI = appRemote.playerAPI, isConnected else {
            print("Cannot control playback – not connected or missing playerAPI")
            return
        }

        resetInactivityTimer()

        if isPaused {
            playerAPI.resume { _, error in
                if let error = error { print("Resume error: \(error.localizedDescription)") }
            }
            startProgressTimer()
        } else {
            playerAPI.pause { _, error in
                if let error = error { print("Pause error: \(error.localizedDescription)") }
            }
            stopProgressTimer()
        }
    }

    func toggleLikeForCurrentTrack() {
        guard let accessToken = self.accessToken else {
            print(" Brak access tokena")
            return
        }

        guard let trackID = lastPlayerState?.track.uri.split(separator: ":").last else {
            print("Nie znaleziono track ID")
            return
        }

        resetInactivityTimer()

        let urlString: String = "https://api.spotify.com/v1/me/tracks?ids=\(trackID)"
        let method: String = isCurrentTrackLiked ? "DELETE" : "PUT"

        guard let url = URL(string: urlString) else {
            print("Błędny URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Błąd podczas aktualizacji like: \(error.localizedDescription)")
                    return
                }

                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 || httpResponse.statusCode == 204 {
                        self.isCurrentTrackLiked.toggle()
                        print("Zmieniono status like na \(self.isCurrentTrackLiked)")
                    } else {
                        print("Błąd: kod statusu \(httpResponse.statusCode)")
                    }
                }
            }
        }.resume()
    }

    func play(uri: String) {
        guard let playerAPI = appRemote.playerAPI, isConnected else {
            print("Cannot play URI – not connected")
            return
        }

        resetInactivityTimer()

        playerAPI.play(uri, callback: { [weak self] _, error in
            if let error = error {
                print("Failed to play URI: \(error.localizedDescription)")
            } else {
                print("Now playing URI: \(uri)")
                DispatchQueue.main.async {
                    self?.currentlyPlayingURI = uri
                }
            }
        })
    }

    func skipToNext() {
        guard let playerAPI = appRemote.playerAPI, isConnected else { return }
        resetInactivityTimer()
        playerAPI.skip(toNext: { _, error in
            if let error = error { print("skip(toNext:) error: \(error.localizedDescription)") }
        })
    }

    func skipToPrevious() {
        guard let playerAPI = appRemote.playerAPI, isConnected else { return }
        resetInactivityTimer()
        playerAPI.skip(toPrevious: { _, error in
            if let error = error { print("skip(toPrevious:) error: \(error.localizedDescription)") }
        })
    }

    func seek(to position: TimeInterval) {
        guard let playerAPI = appRemote.playerAPI, isConnected else { return }
        resetInactivityTimer()
        let positionInMilliseconds = Int(position * 1000)
        playerAPI.seek(toPosition: positionInMilliseconds) { _, error in
            if let error = error {
                print("Seek error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Playlista vs Liked Songs

    func playPlaylistURI(_ uri: String) {
        resetInactivityTimer()

        if uri == "spotify:collection:tracks" {
            print("playPlaylistURI: Liked Songs – używam kontekstu + cache polubionych")
            playLikedSongsContextViaWebAPI()
            preloadLikedTracks()
        } else {
            play(uri: uri)
        }
    }

    // MARK: - Progress Timer

    private func startProgressTimer() {
        progressTimer?.cancel()
        progressTimer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if !self.isPaused, self.currentPosition < self.trackDuration {
                    self.currentPosition += 1
                }
            }
    }

    private func stopProgressTimer() {
        progressTimer?.cancel()
        progressTimer = nil
    }

    // MARK: - Player State

    func fetchPlayerState() {
        guard let playerAPI = appRemote.playerAPI, isConnected else { return }

        playerAPI.getPlayerState { [weak self] result, error in
            if let error = error {
                print("Error getting player state: \(error.localizedDescription)")
            } else if let state = result as? SPTAppRemotePlayerState {
                DispatchQueue.main.async {
                    self?.update(playerState: state)
                }
            }
        }
    }

    func fetchLikeStatusForCurrentTrack() {
        guard let accessToken = self.accessToken else {
            print("Brak accessTokenu")
            return
        }

        guard let uri = lastPlayerState?.track.uri else {
            print("Brak URI aktualnego tracka")
            return
        }

        let components = uri.split(separator: ":")
        guard components.count == 3, components[1] == "track" else {
            print("URI nie jest typu spotify:track:<id> → \(uri)")
            return
        }

        let trackID = components[2]
        let urlString = "https://api.spotify.com/v1/me/tracks/contains?ids=\(trackID)"
        guard let url = URL(string: urlString) else {
            print("Nie udało się stworzyć URL")
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Błąd podczas sprawdzania like: \(error.localizedDescription)")
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("Brak odpowiedzi HTTP")
                return
            }

            guard httpResponse.statusCode == 200 else {
                print("Błąd statusu: \(httpResponse.statusCode)")
                return
            }

            guard let data = data else {
                print("Brak danych w odpowiedzi")
                return
            }

            do {
                let result = try JSONDecoder().decode([Bool].self, from: data)
                DispatchQueue.main.async {
                    self.isCurrentTrackLiked = result.first ?? false
                    print(" \(self.trackName) liked status: \(self.isCurrentTrackLiked)")
                }
            } catch {
                print("Błąd dekodowania JSON: \(error.localizedDescription)")
            }
        }.resume()
    }

    private func update(playerState: SPTAppRemotePlayerState) {
        let previousURI = lastPlayerState?.track.uri
        lastPlayerState = playerState

        trackName = playerState.track.name
        trackArtist = playerState.track.artist.name
        isPaused = playerState.isPaused
        isPlaying = !playerState.isPaused
        currentPosition = Double(playerState.playbackPosition) / 1000.0
        trackDuration = Double(playerState.track.duration) / 1000.0
        currentlyPlayingURI = playerState.track.uri

        UserDefaults.standard.set(playerState.track.uri, forKey: "lastPlayedURI")

        let currentURI = playerState.track.uri

        guard previousURI != currentURI else { return }

        fetchArtwork(for: playerState.track)
        fetchLikeStatusForCurrentTrack()

        resolveBPMUsingGetSongBPM(title: trackName, artist: trackArtist, uri: currentURI)
    }

    private func fetchArtwork(for track: SPTAppRemoteTrack) {
        guard let imageAPI = appRemote.imageAPI else { return }
        let size = CGSize(width: 600, height: 600)

        imageAPI.fetchImage(forItem: track, with: size) { [weak self] result, error in
            if let error = error {
                print("Artwork fetch error: \(error.localizedDescription)")
            } else if let image = result as? UIImage {
                DispatchQueue.main.async {
                    self?.artwork = image
                }
            }
        }
    }


    func updateTargetBPM(_ hrValue: Int?) {
        print("updateTargetBPM wywołane z hrValue=\(String(describing: hrValue))")

        guard let hr = hrValue, hr > 0 else {
            print("updateTargetBPM – brak sensownego HR")
            return
        }

        if museMeTracks.isEmpty {
            print("updateTargetBPM – museMeTracks puste, odpalam preload i wychodzę")
            preloadMuseMeTracks()
            return
        }

        let now = Date()

        let cooldown: TimeInterval = 25
        let sinceLast = now.timeIntervalSince(lastAutoSwitchDate)
        if sinceLast < cooldown {
            print("⏳ updateTargetBPM – cooldown (\(sinceLast)s < \(cooldown)s), pomijam")
            return
        }

        let dropThreshold = 10
        if let last = lastTargetBPM, hr > (last - dropThreshold) {
            print("updateTargetBPM – HR nie spadło o \(dropThreshold) (last=\(last), now=\(hr)), nie przełączam")
            return
        }

        let margin = 1.0
        let target = Double(hr) - margin

        let candidatesBelow: [(SpotifySong, Double)] = museMeTracks.compactMap { song in
            guard let tempo = song.bpm else { return nil }
            guard tempo < target else { return nil }
            return (song, tempo)
        }

        guard let best = candidatesBelow.max(by: { $0.1 < $1.1 })?.0 else {
            print("updateTargetBPM – brak utworów z BPM < HR=\(hr) w MuseMeTracks. Nie przełączam.")
            lastAutoSwitchDate = now
            lastTargetBPM = hr
            return
        }

        if currentlyPlayingURI == best.uri {
            print("updateTargetBPM – już gra \(best.name) [\(best.bpm ?? 0)] – nie zmieniam")
            lastAutoSwitchDate = now
            lastTargetBPM = hr
            return
        }

        resetInactivityTimer()
        play(uri: best.uri)

        lastAutoSwitchDate = now
        lastTargetBPM = hr

        print(" Auto-switch (MuseMe): \(best.name) [\(best.bpm ?? 0) BPM] dla HR \(hr)")
    }

    
    func playBestFromBPMWindow(hr: Int, lower: Int, upper: Int) {
        guard hr > 0 else { return }

        if museMeTracks.isEmpty {
            preloadMuseMeTracks()
            return
        }

        let now = Date()
        let cooldown: TimeInterval = 5
        if now.timeIntervalSince(lastAutoSwitchDate) < cooldown { return }

        let low = Double(max(65, lower))
        let high = Double(upper)

        let candidates: [(SpotifySong, Double)] = museMeTracks.compactMap { s in
            guard let bpm = s.bpm else { return nil }
            guard bpm >= low && bpm <= high else { return nil }
            return (s, bpm)
        }

        guard let best = candidates.max(by: { $0.1 < $1.1 })?.0 else {
            print("Brak utworu w oknie BPM \(Int(low))-\(Int(high)) (HR=\(hr))")
            lastAutoSwitchDate = now
            return
        }

        if currentlyPlayingURI == best.uri {
            lastAutoSwitchDate = now
            return
        }

        play(uri: best.uri)
        lastAutoSwitchDate = now
        print(" Window-switch: \(best.name) [\(best.bpm ?? 0)] BPM, okno \(Int(low))-\(Int(high)) (HR=\(hr))")
    }

    func likeCurrentTrack() {
        guard let trackURI = lastPlayerState?.track.uri,
              let token = accessToken else {
            print("No track or token")
            return
        }

        resetInactivityTimer()

        let uriParts = trackURI.split(separator: ":")
        guard uriParts.count == 3 else {
            print("Invalid track URI format")
            return
        }

        let trackID = uriParts[2]
        let url = URL(string: "https://api.spotify.com/v1/me/tracks?ids=\(trackID)")!

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer", forHTTPHeaderField: "Authorization")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                print("Error liking track: \(error.localizedDescription)")
            } else if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    print("Track liked successfully")
                } else {
                    print("Failed with status: \(httpResponse.statusCode)")
                }
            }
        }.resume()
    }
}

// MARK: - Spotify Delegates

extension SpotifyPlayerViewModel: SPTAppRemoteDelegate {
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        print("Spotify App Remote: connected")

        DispatchQueue.main.async {
            self.connectFallbackTimer?.invalidate()
            self.shouldShowConnectView = false
            self.isConnected = true
        }

        resetInactivityTimer()

        appRemote.playerAPI?.delegate = self

        appRemote.playerAPI?.subscribe(toPlayerState: { _, error in
            if let error = error {
                print("Subscribe error: \(error.localizedDescription)")
            } else {
                print("Subscribed to player state")

                let museMeContext = "spotify:playlist:3FdZ6psubs89K11C2DbQkt"
                print(" Start z playlisty MuseMe: \(museMeContext)")
                self.playContextViaWebAPI(museMeContext)
                self.preloadMuseMeTracks()
            }
        })

    }

    private func startConnectFallbackTimer() {
        connectFallbackTimer?.invalidate()
        connectFallbackTimer = Timer.scheduledTimer(withTimeInterval: 120, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                print("Timeout 2 min – pokazujemy ConnectView")
                self?.shouldShowConnectView = true
            }
        }
    }

    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        print("App Remote disconnected: \(error?.localizedDescription ?? "no reason")")

        DispatchQueue.main.async {
            self.isConnected = false
            self.isPaused = true
            self.currentPosition = 0
        }
        stopProgressTimer()
        cancelInactivityTimer()
        lastPlayerState = nil

        DispatchQueue.main.async {
            self.startConnectFallbackTimer()
            self.connect()
        }
    }

    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        print("Connection failed: \(error?.localizedDescription ?? "no reason")")
        DispatchQueue.main.async {
            self.isConnected = false
            self.isPaused = true
        }
        stopProgressTimer()
        cancelInactivityTimer()
        lastPlayerState = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.connect()
        }
    }
}

extension SpotifyPlayerViewModel: SPTAppRemotePlayerStateDelegate {
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        DispatchQueue.main.async {
            self.update(playerState: playerState)
        }
    }
}
