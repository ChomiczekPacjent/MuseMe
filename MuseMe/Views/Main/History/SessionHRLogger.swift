import Foundation

final class SessionHRLogger {
    private(set) var fileURL: URL?
    private var isActive = false

    func start(mode: String, sessionId: UUID, startTime: Date) {
        let safeMode = mode.replacingOccurrences(of: " ", with: "_")
        let name = "museme_hr_\(safeMode)_\(sessionId.uuidString.prefix(8)).csv"
        let url = documentsDirectory().appendingPathComponent(name)
        fileURL = url
        isActive = true

        let header = "timestamp,secondsFromStart,mode,sessionId,heartRate,trackBPM,trackName,trackArtist,trackUri\n"
        write(text: header, to: url, overwrite: true)
    }

    func addSample(mode: String,
                   sessionId: UUID,
                   startTime: Date,
                   heartRate: Int,
                   trackBPM: Double? = nil,
                   trackName: String? = nil,
                   trackArtist: String? = nil,
                   trackUri: String? = nil) {

        guard isActive, let url = fileURL else { return }
        guard heartRate > 0 else { return }

        let now = Date()
        let seconds = now.timeIntervalSince(startTime)

        let bpmStr = trackBPM.map { String($0) } ?? ""
        let nameStr = escapeCSV(trackName)
        let artistStr = escapeCSV(trackArtist)
        let uriStr = escapeCSV(trackUri)

        let row =
        "\(iso(now))," +
        "\(String(format: "%.3f", seconds))," +
        "\(mode)," +
        "\(sessionId.uuidString)," +
        "\(heartRate)," +
        "\(bpmStr)," +
        "\(nameStr)," +
        "\(artistStr)," +
        "\(uriStr)\n"

        append(text: row, to: url)
    }

    func stop() {
        isActive = false
    }


    private func documentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private func iso(_ date: Date) -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.string(from: date)
    }

    private func escapeCSV(_ value: String?) -> String {
        guard let v = value, !v.isEmpty else { return "" }
        if v.contains(",") || v.contains("\"") || v.contains("\n") {
            return "\"\(v.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return v
    }

    private func write(text: String, to url: URL, overwrite: Bool) {
        do {
            if overwrite {
                try text.data(using: .utf8)?.write(to: url, options: .atomic)
            } else {
                append(text: text, to: url)
            }
        } catch {
            print("SessionHRLogger write error:", error)
        }
    }

    private func append(text: String, to url: URL) {
        do {
            if FileManager.default.fileExists(atPath: url.path) {
                let handle = try FileHandle(forWritingTo: url)
                try handle.seekToEnd()
                if let data = text.data(using: .utf8) {
                    try handle.write(contentsOf: data)
                }
                try handle.close()
            } else {
                try text.data(using: .utf8)?.write(to: url, options: .atomic)
            }
        } catch {
            print("SessionHRLogger append error:", error)
        }
    }
}
