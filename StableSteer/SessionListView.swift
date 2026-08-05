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
                            VStack(alignment: .leading) {
                                Text(session.name).font(.headline)
                                Text("\(session.samples.count) samples · \(String(format: "%.1f", session.duration))s")
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
}

#Preview {
    SessionListView()
}
