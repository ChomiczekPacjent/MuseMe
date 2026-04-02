import SwiftUI

struct HomeView: View {
    @EnvironmentObject var sessionStore: SessionStore
    @State private var showMainPage = false

    private var report: MonthlyReport {
        MonthlyReport.build(from: sessionStore.sessions, for: Date())
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                Text("Monthly Summary")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // MARK: Monthly report KPI
                SectionBackground {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(report.title)
                            .font(.subheadline)
                            .foregroundColor(.white)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            KPIBox(title: "Sessions", value: "\(report.sessionsCount)", icon: "bolt.fill")
                            KPIBox(title: "Total time", value: report.totalTimeText, icon: "clock.fill")
                            KPIBox(title: "Avg session", value: report.avgSessionText, icon: "timer")
                            KPIBox(title: "Avg HR", value: report.avgHRText ?? "—", icon: "heart.fill")
                        }

                        Text(report.hrCoverageText)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }

                

                if !report.insights.isEmpty {
                    SectionBackground {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Insights")
                                .font(.subheadline)
                                .foregroundColor(.white)

                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(report.insights, id: \.self) { line in
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("•").foregroundColor(.gray)
                                        Text(line).foregroundColor(.gray)
                                    }
                                    .font(.subheadline)
                                }
                            }
                        }
                    }
                }

            }
            .padding(.vertical, 20)
            .padding(.horizontal, 16)
        }
        .background(Color.black.ignoresSafeArea())
        .fullScreenCover(isPresented: $showMainPage) {
            MainPageView()
                .preferredColorScheme(.dark)
        }
    }
}


private struct MonthlyReport {
    let title: String

    let sessionsCount: Int
    let totalSeconds: Int
    let avgSessionSeconds: Int

    let avgHR: Int?
    let hrAvailable: Int

    let avgHRRange: Int?
    let rangeAvailable: Int

    var totalTimeText: String { formatHMS(totalSeconds) }
    var avgSessionText: String { formatMS(avgSessionSeconds) }

    var avgHRText: String? {
        guard let avgHR else { return nil }
        return "\(avgHR)"
    }

    var avgHRRangeText: String? {
        guard let avgHRRange else { return nil }
        return "\(avgHRRange) bpm"
    }

    var hrCoverageText: String {
        if sessionsCount == 0 { return "No sessions yet." }
        if hrAvailable == 0 { return "No HR data available in this period." }
        return "HR available for \(hrAvailable)/\(sessionsCount) sessions."
    }

    var consistencyLabel: String {
        guard let r = avgHRRange else { return "—" }
        switch r {
        case 0...10: return "Great"
        case 11...20: return "Good"
        case 21...35: return "Okay"
        default: return "Unstable"
        }
    }

    var insights: [String] {
        guard sessionsCount > 0 else { return [] }

        var out: [String] = []
        out.append("You completed \(sessionsCount) session\(sessionsCount == 1 ? "" : "s") in this period.")
        out.append("Average session duration: \(formatMS(avgSessionSeconds)).")

        if let avgHR {
            out.append("Average heart rate during sessions: \(avgHR) bpm.")
        } else {
            out.append("Connect / record HR to unlock heart rate insights.")
        }

        if let avgHRRange {
            out.append("Typical HR swing inside a session: \(avgHRRange) bpm (max−min).")
        }

        return Array(out.prefix(4))
    }

    static func build(from sessions: [MuseSession], for date: Date) -> MonthlyReport {
        let cal = Calendar.current
        let startOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: date)) ?? date
        let endOfMonth = cal.date(byAdding: .month, value: 1, to: startOfMonth) ?? date

        let monthSessions = sessions.filter { $0.startTime >= startOfMonth && $0.startTime < endOfMonth }

        let count = monthSessions.count
        let total = monthSessions.reduce(0) { $0 + max(0, $1.duration) }
        let avgSession = count > 0 ? total / count : 0

        let hrSessions = monthSessions.compactMap { $0.avgHR }
        let avgHR = hrSessions.isEmpty ? nil : Int(Double(hrSessions.reduce(0, +)) / Double(hrSessions.count))

        let ranges: [Int] = monthSessions.compactMap { s in
            guard let min = s.minHR, let max = s.maxHR else { return nil }
            let r = max - min
            return r >= 0 ? r : nil
        }
        let avgRange = ranges.isEmpty ? nil : Int(Double(ranges.reduce(0, +)) / Double(ranges.count))

        let title = "This month"

        return MonthlyReport(
            title: title,
            sessionsCount: count,
            totalSeconds: total,
            avgSessionSeconds: avgSession,
            avgHR: avgHR,
            hrAvailable: hrSessions.count,
            avgHRRange: avgRange,
            rangeAvailable: ranges.count
        )
    }

    private func formatMS(_ sec: Int) -> String {
        let m = max(0, sec) / 60
        let s = max(0, sec) % 60
        if m > 0 { return "\(m)m \(s)s" }
        return "\(s)s"
    }

    private func formatHMS(_ sec: Int) -> String {
        let t = max(0, sec)
        let h = t / 3600
        let m = (t % 3600) / 60
        let s = t % 60

        if h > 0 { return "\(h)h \(m)m" }
        if m > 0 { return "\(m)m \(s)s" }
        return "\(s)s"
    }
}


private struct SectionBackground<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        content
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.spotifyBackground)
            .cornerRadius(14)
    }
}

private struct KPIBox: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.purple)
                Spacer()
            }

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 90, alignment: .leading)
        .background(Color.white.opacity(0.06))
        .cornerRadius(12)
    }
}

private struct EffectCard: View {
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text(subtitle)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
        .background(Color.white.opacity(0.06))
        .cornerRadius(12)
    }
}
