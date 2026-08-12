import SwiftUI

struct SessionListView: View {
    @ObservedObject var manager = PhoneSessionManager.shared

    @State private var isSelecting = false
    @State private var selectedIDs: [UUID] = [] // ordered, max 2

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
                        row(for: session)
                    }
                }
            }
            .navigationTitle("Stability Sessions")
            .navigationDestination(for: RecordingSession.self) { session in
                StabilityChartView(session: session)
            }
            .navigationDestination(for: ComparisonPair.self) { pair in
                CompareChartView(pair: pair)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isSelecting ? "Cancel" : "Compare") {
                        isSelecting.toggle()
                        selectedIDs.removeAll()
                    }
                    .disabled(!isSelecting && manager.sessions.count < 2)
                }
            }
            .safeAreaInset(edge: .bottom) {
                if isSelecting, let pair = comparisonPair {
                    NavigationLink(value: pair) {
                        Text("Compare Selected")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                    .background(.bar)
                }
            }
        }
    }

    @ViewBuilder
    private func row(for session: RecordingSession) -> some View {
        if isSelecting {
            Button {
                toggleSelection(session.id)
            } label: {
                HStack {
                    Image(systemName: selectedIDs.contains(session.id) ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(selectedIDs.contains(session.id) ? .blue : .secondary)
                    sessionLabels(for: session)
                }
            }
            .buttonStyle(.plain)
        } else {
            NavigationLink(value: session) {
                sessionLabels(for: session)
            }
        }
    }

    private func sessionLabels(for session: RecordingSession) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title(for: session))
                .font(.headline)
            Text("\(session.startDate.formatted(date: .abbreviated, time: .shortened)) · \(formattedDuration(session.duration))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func toggleSelection(_ id: UUID) {
        if let index = selectedIDs.firstIndex(of: id) {
            selectedIDs.remove(at: index)
        } else if selectedIDs.count < 2 {
            selectedIDs.append(id)
        }
        // Ignore taps once two are already selected — no swap, just no-op,
        // so picking two is a deliberate act rather than a moving target.
    }

    private var comparisonPair: ComparisonPair? {
        guard selectedIDs.count == 2 else { return nil }
        let picked = selectedIDs.compactMap { id in manager.sessions.first(where: { $0.id == id }) }
        guard picked.count == 2 else { return nil }
        return ComparisonPair(
            first: ComparisonEntry(label: title(for: picked[0]), session: picked[0]),
            second: ComparisonEntry(label: title(for: picked[1]), session: picked[1])
        )
    }

    private func title(for session: RecordingSession) -> String {
        "\(session.circuitName) Session \(sessionNumber(for: session))"
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
