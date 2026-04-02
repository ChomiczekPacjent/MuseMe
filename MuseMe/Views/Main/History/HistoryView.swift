import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var sessionStore: SessionStore

    private var sortedNewestFirst: [MuseSession] {
        sessionStore.sessions.sorted { $0.startTime > $1.startTime }
    }

    private var sortedOldestFirst: [MuseSession] {
        sessionStore.sessions.sorted { $0.startTime < $1.startTime }
    }

    private var sessionNumberById: [UUID: Int] {
        Dictionary(uniqueKeysWithValues:
            sortedOldestFirst.enumerated().map { idx, session in
                (session.id, idx + 1)
            }
        )
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(sortedNewestFirst) { session in
                    NavigationLink {
                        SessionDetailView(session: session)
                    } label: {
                        HistoryRow(
                            title: "Session \(sessionNumberById[session.id] ?? 0)",
                            date: session.startTime,
                            durationSeconds: session.duration
                        )
                    }
                    .listRowBackground(Color.black)
                    .listRowSeparatorTint(.white.opacity(0.15))
                }
                .onDelete(perform: deleteItems) 
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.black)
            .navigationTitle("Your sessions")
            .navigationBarTitleDisplayMode(.large)
        }
        .preferredColorScheme(.dark)
    }

    private func deleteItems(at offsets: IndexSet) {
        let current = sortedNewestFirst
        for index in offsets {
            sessionStore.deleteSession(current[index])
        }
    }
}



private struct HistoryRow: View {
    let title: String
    let date: Date
    let durationSeconds: Int

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(dateText)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }

            Spacer()

            Text(durationMMSS)
                .font(.subheadline)
                .foregroundColor(.gray)
                .monospacedDigit()
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }

    private var dateText: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "d MMMM yyyy"
        return f.string(from: date)
    }

    private var durationMMSS: String {
        let m = durationSeconds / 60
        let s = durationSeconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
