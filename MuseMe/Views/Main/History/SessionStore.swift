import Foundation

class SessionStore: ObservableObject {
    @Published var sessions: [MuseSession] = [] {
        didSet {
            saveSessions()
        }
    }
    
    private let key = "savedMuseSessions"
    
    init() {
        loadSessions()
    }
    
    func addSession(
        start: Date,
        end: Date,
        avgHR: Int?,
        maxHR: Int?,
        minHR: Int?,
        mode: String?
    ) {
        let session = MuseSession(
            startTime: start,
            endTime: end,
            avgHR: avgHR,
            maxHR: maxHR,
            minHR: minHR,
            mode: mode
        )
        
        sessions.append(session)
        
        NotificationsViewModel.shared.addNotification(
            title: "Sesja zakończona",
            body: "Twoja sesja trwała \(session.duration) sekund. Średnie tętno: \(avgHR ?? 0)."
        )
        
        NotificationManager.shared.notifySessionEnded()
    }
    
    func deleteSession(_ session: MuseSession) {
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions.remove(at: index)
        }
    }
    
    func clearAllSessions() {
        sessions.removeAll()
    }
    
    private func saveSessions() {
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    private func loadSessions() {
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode([MuseSession].self, from: data) {
            sessions = saved
        }
    }
}
