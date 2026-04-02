import Combine
import Foundation

enum MusicMode {
    case heal, match, push
}

enum MusicEngineType {
    case simpleZones
    case bpmBased
}

private enum HRZone {
    case low, medium, high

    static func from(hr: Int) -> HRZone {
        switch hr {
        case ..<90: return .low
        case 90..<130: return .medium
        default: return .high
        }
    }
}

struct ZonePlaylists {
    var lowURI: String?
    var mediumURI: String?
    var highURI: String?

    fileprivate func uri(for zone: HRZone) -> String? {
        switch zone {
        case .low: return lowURI
        case .medium: return mediumURI
        case .high: return highURI
        }
    }
}

final class BPMChanger: ObservableObject {
    static let shared = BPMChanger()

    private var heartRateCancellable: AnyCancellable?
    private var bleCancellable: AnyCancellable?

    private let healthStore: HealthStore
    private let heartRateBLE = HeartRateBLE.shared

    @Published var currentTargetBPM: Int = 0
    @Published private(set) var currentMode: MusicMode = .match
    @Published private(set) var currentEngine: MusicEngineType = .bpmBased
    @Published private(set) var isSessionActive: Bool = false

    private var zonePlaylists = ZonePlaylists(lowURI: nil, mediumURI: nil, highURI: nil)
    private var lastPlayedPlaylistURI: String?

    private var lastDecisionAt: Date = .distantPast
    private var lastDecisionHR: Int? = nil

    private let bpmFloor: Int = 65
    
    // Dane użytkownika z wizard / Firebase
    private var profileData: ProfileData?

    private func threshold(for mode: MusicMode) -> Int {
        switch mode {
        case .heal:  return 5
        case .match: return 7
        case .push:  return 8
        }
    }

    private func cooldown(for mode: MusicMode) -> TimeInterval {
        switch mode {
        case .heal:  return 25
        case .match: return 30
        case .push:  return 20
        }
    }

    private func bpmWindow(for mode: MusicMode, hr: Int) -> (lower: Int, upper: Int) {
        switch mode {
        case .heal:
            let desiredGap = 15
            let windowWidth = 6

            let target = max(bpmFloor, hr - desiredGap)
            let lower = max(bpmFloor, target - windowWidth)
            let upper = target
            return (lower, upper)

        case .match:
            return (max(bpmFloor, hr - 5), min(200, hr + 5))

        case .push:
            let target = min(200, Int(Double(hr) * 1.15))
            return (max(bpmFloor, target - 8), min(200, target + 4))
        }
    }

    private init() {
        self.healthStore = HealthStore()
    }

    func configureZonePlaylists(low: String?, medium: String?, high: String?) {
        zonePlaylists = ZonePlaylists(lowURI: low, mediumURI: medium, highURI: high)
    }
    
    func updateProfileData(_ data: ProfileData) {
        self.profileData = data
        print("BPMChanger profile updated. gender=\(data.gender), birthDate=\(data.birthDate)")
    }

    func start(mode: MusicMode) {
        start(mode: mode, engine: .bpmBased)
    }

    func start(mode: MusicMode, engine: MusicEngineType) {
        currentMode = mode
        currentEngine = engine
        isSessionActive = true

        lastDecisionAt = .distantPast
        lastDecisionHR = nil

        observeHeartRate()
        heartRateBLE.start()
        healthStore.startHeartRateUpdates()
    }

    func stop() {
        heartRateCancellable?.cancel()
        bleCancellable?.cancel()

        currentTargetBPM = 0
        isSessionActive = false
        lastPlayedPlaylistURI = nil

        lastDecisionAt = .distantPast
        lastDecisionHR = nil

        SpotifyPlayerViewModel.shared.updateTargetBPM(nil)
        heartRateBLE.stop()
        healthStore.stopHeartRateUpdates()
    }

    private func observeHeartRate() {
        bleCancellable = heartRateBLE.$heartRateBLE
            .filter { $0 > 0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] hr in
                self?.processHeartRate(Int(hr), source: "BLE")
            }

        heartRateCancellable = healthStore.$heartRate
            .filter { $0 > 0 }
            .throttle(for: .seconds(20), scheduler: DispatchQueue.main, latest: true)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] hr in
                guard let self = self else { return }
                if self.heartRateBLE.heartRateBLE == 0 {
                    self.processHeartRate(Int(hr), source: "HK")
                }
            }
    }

    private func processHeartRate(_ hr: Int, source: String) {
        guard isSessionActive, hr > 30 else { return }

        // PushMe - górna granica bezpieczeństwa
        if currentMode == .push, hr >= maxSafeHR() {
            print("Push stopped (\(source)): HR \(hr) >= maxSafeHR \(maxSafeHR())")
            stop()
            return
        }

        // HealMe - dolna granica, nie schodzimy niżej
        if currentMode == .heal, hr <= healMinHR() {
            print("Heal floor reached (\(source)): HR \(hr) <= healMinHR \(healMinHR())")
            return
        }

        if hr < 100, SpotifyPlayerViewModel.shared.isPaused {
            SpotifyPlayerViewModel.shared.togglePlayPause()
        }

        if currentEngine == .simpleZones {
            applySimpleEngine(hr: hr)
            return
        }

        guard shouldChangeTrack(hr: hr) else { return }

        let (lower, upper) = bpmWindow(for: currentMode, hr: hr)
        currentTargetBPM = upper

        print("DECISION(\(source)) mode=\(currentMode) HR=\(hr) window=\(lower)-\(upper)")

        SpotifyPlayerViewModel.shared.playBestFromBPMWindow(
            hr: hr,
            lower: lower,
            upper: upper
        )

        lastDecisionAt = Date()
        lastDecisionHR = hr
    }

    private func shouldChangeTrack(hr: Int) -> Bool {
        let now = Date()
        let cd = cooldown(for: currentMode)

        if now.timeIntervalSince(lastDecisionAt) < cd {
            return false
        }

        let th = threshold(for: currentMode)

        guard let last = lastDecisionHR else {
            return true
        }

        let delta = hr - last

        switch currentMode {
        case .heal:
            return delta <= -th

        case .match, .push:
            return abs(delta) >= th
        }
    }

    private func applySimpleEngine(hr: Int) {
        let zone = HRZone.from(hr: hr)
        guard let playlistURI = zonePlaylists.uri(for: zone) else { return }
        guard playlistURI != lastPlayedPlaylistURI else { return }
        lastPlayedPlaylistURI = playlistURI
    }
}

// MARK: - Safety thresholds

private extension BPMChanger {
    func resolvedAge() -> Int? {
        guard let birthDate = profileData?.birthDate else { return nil }
        let calendar = Calendar.current
        return calendar.dateComponents([.year], from: birthDate, to: Date()).year
    }

    func maxSafeHR() -> Int {
        guard let age = resolvedAge(), age > 0 else {
            return 190
        }
        return Int((208.0 - 0.7 * Double(age)).rounded())
    }

    func healMinHR() -> Int {
        let gender = profileData?.gender.lowercased() ?? ""

        let base: Int
        if gender.contains("male") {
            base = 68
        } else if gender.contains("female") {
            base = 71
        } else {
            base = 70
        }

        let age = resolvedAge() ?? 30

        let ageAdjustment: Int
        switch age {
        case ..<25:
            ageAdjustment = -3
        case 25...34:
            ageAdjustment = -1
        case 35...49:
            ageAdjustment = 1
        case 50...59:
            ageAdjustment = 3
        default:
            ageAdjustment = 5
        }

        return base + ageAdjustment
    }
}
