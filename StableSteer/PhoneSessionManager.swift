import Foundation
import WatchConnectivity
import Combine

/// Receives finished RecordingSessions transferred from the Watch and
/// persists them to disk so they survive app relaunches.
final class PhoneSessionManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = PhoneSessionManager()

    @Published var sessions: [RecordingSession] = []

    private let storageURL = FileManager.default
        .urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("sessions.json")

    private override init() {
        super.init()
        loadFromDisk()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { WCSession.default.activate() }

    // Called automatically when a transferFile from the Watch completes.
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        do {
            let data = try Data(contentsOf: file.fileURL)
            let recordingSession = try JSONDecoder().decode(RecordingSession.self, from: data)
            DispatchQueue.main.async {
                self.sessions.insert(recordingSession, at: 0)
                self.saveToDisk()
            }
        } catch {
            print("Failed to decode incoming session: \(error)")
        }
    }

    private func saveToDisk() {
        do {
            let data = try JSONEncoder().encode(sessions)
            try data.write(to: storageURL)
        } catch {
            print("Failed to save sessions: \(error)")
        }
    }

    private func loadFromDisk() {
        guard let data = try? Data(contentsOf: storageURL) else { return }
        sessions = (try? JSONDecoder().decode([RecordingSession].self, from: data)) ?? []
    }

    /// Sets a session's custom name. Passing an empty/whitespace-only string
    /// clears it, reverting the display title back to the auto-generated
    /// "<circuit> Session <n>" form.
    func rename(sessionID: UUID, to newName: String) {
        guard let index = sessions.firstIndex(where: { $0.id == sessionID }) else { return }
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        sessions[index].customName = trimmed.isEmpty ? nil : trimmed
        saveToDisk()
    }

    /// The single source of truth for how a session's title is shown,
    /// everywhere it's shown: the person's custom name if they've set one,
    /// otherwise "<circuit> Session <n>", where n is that session's
    /// chronological position among all sessions on the same circuit
    /// (1 = first ever recorded there).
    func displayTitle(for session: RecordingSession) -> String {
        if let customName = session.customName, !customName.isEmpty {
            return customName
        }
        let sameCircuit = sessions
            .filter { $0.circuitName == session.circuitName }
            .sorted { $0.startDate < $1.startDate }
        let number = (sameCircuit.firstIndex(where: { $0.id == session.id }) ?? 0) + 1
        return "\(session.circuitName) Session \(number)"
    }
}
