import Foundation
import Combine

enum SessionMode: String {
    case match = "MatchMe"
    case heal  = "HealMe"
    case push  = "PushMe"

    var bpmMode: MusicMode {
        switch self {
        case .match: return .match
        case .heal:  return .heal
        case .push:  return .push
        }
    }

    var storeMode: String {
        rawValue.lowercased()
    }
}

class ActiveSessionManager: ObservableObject {
    static let shared = ActiveSessionManager()

    @Published var isSessionActive: Bool = false
    @Published var currentMode: SessionMode?
    @Published var sessionStartTime: Date?

    private var sessionId: UUID?
    private var timer: Timer?
    private var hrLogger = SessionHRLogger()

    private init() {}

    func startSession(mode: SessionMode, sessionStore: SessionStore) {
        guard !isSessionActive else { return }

        let start = Date()
        let id = UUID()

        sessionStartTime = start
        sessionId = id
        currentMode = mode
        isSessionActive = true

        HRSessionTracker.shared.reset()
        hrLogger.start(mode: mode.rawValue, sessionId: id, startTime: start)

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            let vm = SpotifyPlayerViewModel.shared
            let hr = Int(HeartRateBLE.shared.heartRateBLE)

            self.hrLogger.addSample(
                mode: mode.rawValue,
                sessionId: id,
                startTime: start,
                heartRate: hr,
                trackBPM: vm.trackBPM,
                trackName: vm.trackName,
                trackArtist: vm.trackArtist,
                trackUri: vm.currentlyPlayingURI
            )
        }

        BPMChanger.shared.start(mode: mode.bpmMode)
    }

    func stopSession(sessionStore: SessionStore) {
        guard isSessionActive, let mode = currentMode else { return }

        let end = Date()

        timer?.invalidate()
        timer = nil
        hrLogger.stop()
        isSessionActive = false

        if let start = sessionStartTime {
            sessionStore.addSession(
                start: start,
                end: end,
                avgHR: HRSessionTracker.shared.avg,
                maxHR: HRSessionTracker.shared.max,
                minHR: HRSessionTracker.shared.min,
                mode: mode.storeMode
            )
            print("HR CSV:", hrLogger.fileURL?.path ?? "nil")
        }

        sessionStartTime = nil
        sessionId = nil
        currentMode = nil

        BPMChanger.shared.stop()
        HRSessionTracker.shared.reset()
    }
}
