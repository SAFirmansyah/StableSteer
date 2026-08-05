import Foundation
import CoreMotion
import Combine

/// Wraps CMMotionManager and turns device-motion updates into MotionSamples.
/// Runs entirely on the Watch — no phone connection required to record.
final class MotionRecorder: ObservableObject {
    private let motionManager = CMMotionManager()
    private let queue = OperationQueue()

    @Published var isRecording = false
    @Published var elapsedTime: TimeInterval = 0
    @Published var sampleCount = 0

    private var samples: [MotionSample] = []
    private var startTimestamp: TimeInterval = 0
    let sampleRateHz: Double = 50.0

    func start() {
        guard motionManager.isDeviceMotionAvailable else {
            print("Device motion not available on this device")
            return
        }
        samples.removeAll()
        sampleCount = 0
        elapsedTime = 0
        startTimestamp = 0
        isRecording = true

        motionManager.deviceMotionUpdateInterval = 1.0 / sampleRateHz
        queue.qualityOfService = .userInitiated

        // .xArbitraryZVertical gives a stable reference frame without needing
        // magnetometer calibration, which is fine for a relative stability metric.
        motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: queue) { [weak self] motion, error in
            guard let self, let motion else { return }
            if self.startTimestamp == 0 {
                self.startTimestamp = motion.timestamp
            }
            let elapsed = motion.timestamp - self.startTimestamp
            let sample = MotionSample(
                elapsedTime: elapsed,
                attitudeX: motion.attitude.pitch
            )
            self.samples.append(sample)

            DispatchQueue.main.async {
                self.elapsedTime = elapsed
                self.sampleCount = self.samples.count
            }
        }
    }

    /// Stops recording and packages everything captured into a RecordingSession.
    @discardableResult
    func stop(named name: String) -> RecordingSession {
        motionManager.stopDeviceMotionUpdates()
        isRecording = false
        let session = RecordingSession(
            name: name,
            startDate: Date().addingTimeInterval(-elapsedTime),
            sampleRateHz: sampleRateHz,
            samples: samples
        )
        return session
    }
}
