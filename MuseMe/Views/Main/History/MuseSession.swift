import Foundation

struct MuseSession: Identifiable, Codable {
    let id: UUID
    let startTime: Date
    let endTime: Date
    let avgHR: Int?
    let maxHR: Int?
    let minHR: Int?
    let duration: Int
    let mode: String?

    init(
        startTime: Date,
        endTime: Date,
        avgHR: Int? = nil,
        maxHR: Int? = nil,
        minHR: Int? = nil,
        mode: String? = nil
    ) {
        self.id = UUID()
        self.startTime = startTime
        self.endTime = endTime
        self.avgHR = avgHR
        self.maxHR = maxHR
        self.minHR = minHR
        self.mode = mode
        self.duration = Int(endTime.timeIntervalSince(startTime))
    }
}
