import Foundation
import WatchConnectivity
import Combine

/// Sends a finished recording to the iPhone as a file transfer.
/// transferFile queues in the background and delivers once the phone is
/// reachable, so you don't need the phone nearby while recording.
final class WatchSessionManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchSessionManager()
    @Published var lastTransferStatus: String = ""

    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error {
            print("WCSession activation error: \(error.localizedDescription)")
        }
    }

    func send(_ recordingSession: RecordingSession) {
        guard WCSession.default.activationState == .activated else {
            lastTransferStatus = "Watch connectivity session not activated"
            return
        }
        do {
            let data = try JSONEncoder().encode(recordingSession)
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(recordingSession.id.uuidString).json")
            try data.write(to: tempURL)
            WCSession.default.transferFile(tempURL, metadata: ["type": "stabilitySession"])
            lastTransferStatus = "Sending \(recordingSession.samples.count) samples…"
        } catch {
            lastTransferStatus = "Failed to send: \(error.localizedDescription)"
        }
    }
}
