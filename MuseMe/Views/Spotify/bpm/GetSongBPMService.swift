//
//  GetSongBPMService.swift
//  MuseMe
//
//  Created by Błażej Faber on 01/12/2025.
//

import Foundation


struct GetSongBPMSearchResponse: Decodable {

    struct Artist: Decodable {
        let name: String
    }

    struct Song: Decodable {
        let id: String
        let title: String
        let tempoString: String?
        let artist: Artist?

        enum CodingKeys: String, CodingKey {
            case id
            case title
            case tempo
            case artist
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(String.self, forKey: .id)
            title = try container.decode(String.self, forKey: .title)

            if let tempoStr = try? container.decode(String.self, forKey: .tempo) {
                tempoString = tempoStr
            } else if let tempoNum = try? container.decode(Double.self, forKey: .tempo) {
                tempoString = String(tempoNum)
            } else {
                tempoString = nil
            }

            artist = try? container.decode(Artist.self, forKey: .artist)
        }

        var tempo: Double? {
            guard let tempoString else { return nil }
            return Double(tempoString)
        }
    }

    let search: [Song]
}


final class GetSongBPMService {

    static let shared = GetSongBPMService()

    private let apiKey = "YOUR_BPM_API_KEY"

    private let baseURL = URL(string: "https://api.getsong.co")!

    private var bpmCache: [String: Double] = [:]

    private init() {}

    func fetchBPM(
        title: String,
        artist: String?,
        completion: @escaping (Double?) -> Void
    ) {
        let normalizedKey = Self.normalizedKey(title: title, artist: artist)

        if let cached = bpmCache[normalizedKey] {
            print(" GetSongBPM – cache hit \(normalizedKey) = \(cached)")
            DispatchQueue.main.async { completion(cached) }
            return
        }

        var lookup = "song:\(title)"
        if let artist = artist, !artist.isEmpty {
            lookup += " artist:\(artist)"
        }

        var components = URLComponents(url: baseURL.appendingPathComponent("/search/"),
                                       resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "type", value: "both"),
            URLQueryItem(name: "lookup", value: lookup)
        ]

        guard let url = components.url else {
            print(" GetSongBPM – nie udało się zbudować URL")
            DispatchQueue.main.async { completion(nil) }
            return
        }

        print(" GetSongBPM request: \(url.absoluteString)")

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                print(" GetSongBPM error: \(error.localizedDescription)")
                DispatchQueue.main.async { completion(nil) }
                return
            }

            guard let http = response as? HTTPURLResponse else {
                print(" GetSongBPM – brak HTTPURLResponse")
                DispatchQueue.main.async { completion(nil) }
                return
            }

            guard http.statusCode == 200 else {
                let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? "<no body>"
                print("GetSongBPM – HTTP \(http.statusCode). Body: \(body)")
                DispatchQueue.main.async { completion(nil) }
                return
            }

            guard let data = data else {
                print("GetSongBPM – brak danych")
                DispatchQueue.main.async { completion(nil) }
                return
            }

            do {
                let decoded = try JSONDecoder().decode(GetSongBPMSearchResponse.self, from: data)

                guard let first = decoded.search.first else {
                    print(" GetSongBPM – brak wyników dla \(title) / \(artist ?? "-")")
                    DispatchQueue.main.async { completion(nil) }
                    return
                }

                guard let bpm = first.tempo else {
                    print(" GetSongBPM – brak pola tempo w pierwszym wyniku")
                    DispatchQueue.main.async { completion(nil) }
                    return
                }

                print("GetSongBPM – \(first.title) [\(first.artist?.name ?? "-")] tempo = \(bpm)")

                self.bpmCache[normalizedKey] = bpm

                DispatchQueue.main.async { completion(bpm) }
            } catch {
                print("GetSongBPM – błąd dekodowania JSON: \(error)")
                if let str = String(data: data, encoding: .utf8) {
                    print("Body:\n\(str)")
                }
                DispatchQueue.main.async { completion(nil) }
            }
        }.resume()
    }


    private static func normalizedKey(title: String, artist: String?) -> String {
        let t = title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let a = (artist ?? "").lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return "\(t)|\(a)"
    }
}
