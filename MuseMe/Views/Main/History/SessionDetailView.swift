import SwiftUI

struct SessionDetailView: View {
    let session: MuseSession

    @Environment(\.dismiss) private var dismiss

    private func sessionComment() -> String {
        let duration = session.duration
        let minHR = session.minHR ?? 0
        let maxHR = session.maxHR ?? 0

        if duration < 60 || minHR == 0 || maxHR == 0 {
            return "The session was too short to provide a meaningful data."
        }

        let diff = maxHR - minHR
        let durationString = formatDuration(duration)

        if diff > 0 {
            return "Over the course of \(durationString), your heart rate increased by \(diff) BPM."
        } else if diff < 0 {
            return "Over the course of \(durationString), your heart rate decreased by \(abs(diff)) BPM."
        } else {
            return "Over the course of \(durationString), your heart rate remained steady."
        }
    }

    private func formatDuration(_ sec: Int) -> String {
        let h = sec / 3600
        let m = (sec % 3600) / 60
        let s = sec % 60

        if h > 0 { return "\(h)h \(m)m \(s)s" }
        if m > 0 { return "\(m)m \(s)s" }
        return "\(s)s"
    }

    private func formattedMode() -> String {
        switch session.mode?.lowercased() {
        case "heal", "healme":
            return "HealMe"
        case "match", "matchme":
            return "MatchMe"
        case "push", "pushme":
            return "PushMe"
        default:
            return "No data"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {

            VStack(alignment: .leading, spacing: 12) {
                Text("Session summary")
                    .font(.headline)
                    .foregroundColor(.white)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Max HR")
                            .foregroundColor(.gray)
                        Text("\(session.maxHR ?? 0)")
                            .foregroundColor(.purple)
                            .font(.title3)
                            .fontWeight(.semibold)
                    }

                    Spacer()

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Min HR")
                            .foregroundColor(.gray)
                        Text("\(session.minHR ?? 0)")
                            .foregroundColor(.purple)
                            .font(.title3)
                            .fontWeight(.semibold)
                    }

                    Spacer()

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Avg HR")
                            .foregroundColor(.gray)
                        Text("\(session.avgHR ?? 0)")
                            .foregroundColor(.purple)
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Mode")
                        .foregroundColor(.gray)
                    Text(formattedMode())
                        .foregroundColor(.white)
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Duration")
                        .foregroundColor(.gray)
                    Text(formatDuration(session.duration))
                        .foregroundColor(.white)
                        .font(.title3)
                }

                Text(sessionComment())
                    .foregroundColor(.white)
                    .font(.body)
                    .padding(.top, 8)
            }
            .padding(.horizontal)

            Spacer()
        }
        .background(Color.black.ignoresSafeArea())
        .highPriorityGesture(
            DragGesture().onEnded { value in
                if value.translation.height > 80 {
                    dismiss()
                }
            }
        )
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Sessions")
                    }
                }
                .foregroundColor(.white)
            }
        }
        .tint(.white)
    }
}
