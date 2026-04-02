import Foundation
import UserNotifications

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    private init() { }

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Błąd podczas żądania autoryzacji: \(error)")
            } else {
                print(granted ? "Powiadomienia dozwolone" : "Powiadomienia niedozwolone")
            }
        }
    }

    func notifySessionEnded() {
        let content = UNMutableNotificationContent()
        content.title = "Sesja zakończona"
        content.body = "Twoja sesja dobiegła końca. Świetna robota!"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "SESSION_ENDED", 
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}
