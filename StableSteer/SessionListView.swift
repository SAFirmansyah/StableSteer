import SwiftUI

struct SessionListView: View {
    @ObservedObject var manager = PhoneSessionManager.shared

    var body: some View {
        NavigationStack {
            List {
                if manager.sessions.isEmpty {
                    ContentUnavailableView(
                        "No Sessions Yet",
                        systemImage: "waveform.path.ecg",
                        description: Text("Record a session on your Apple Watch to see it here.")
                    )
                } else {
                    ForEach(manager.sessions) { session in
                        NavigationLink(value: session) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(session.circuitName) Session \(sessionNumber(for: session))")
                                    .font(.headline)
                                Text("\(session.startDate.formatted(date: .abbreviated, time: .shortened)) · \(formattedDuration(session.duration))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Stability Sessions")
            .navigationDestination(for: RecordingSession.self) { session in
                StabilityChartView(session: session)
            }
        }
    }

    /// This session's position among all sessions recorded on the same
    /// circuit, ordered chronologically (1 = first ever recorded there),
    /// independent of how the list itself is sorted for display.
    private func sessionNumber(for session: RecordingSession) -> Int {
        let sameCircuit = manager.sessions
            .filter { $0.circuitName == session.circuitName }
            .sorted { $0.startDate < $1.startDate }
        return (sameCircuit.firstIndex(where: { $0.id == session.id }) ?? 0) + 1
    }

    private func formattedDuration(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    SessionListView()
}
