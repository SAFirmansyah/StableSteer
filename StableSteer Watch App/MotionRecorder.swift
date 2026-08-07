import Foundation
import CoreMotion
import Combine
import WatchKit

/// Wraps CMMotionManager and turns device-motion updates into MotionSamples.
/// Runs entirely on the Watch — no phone connection required to record.
final class MotionRecorder: ObservableObject {
    private let motionManager = CMMotionManager()
    private let queue = OperationQueue()

    @Published var isRecording = false
    @Published var elapsedTime: TimeInterval = 0
    @Published var sampleCount = 0

    @Published var isCountingDown = false
    @Published var countdownRemaining = 0

    @Published var isCalibrating = false
    @Published var calibrationProgress: Double = 0 // 0...1, for a progress bar

    private var samples: [MotionSample] = []
    private var startTimestamp: TimeInterval = 0
    let sampleRateHz: Double = 100.0 // CoreMotion clamps to the device's actual max if this isn't achievable

    /// Radians subtracted from every raw pitch reading so the calibrated
    /// neutral position reads as 0°. Set by calibrate().
    private(set) var calibrationOffset: Double = 0
    private let calibrationDuration: TimeInterval = 10.0 // well under the 60s ceiling
    private let startCountdownSeconds = 3 // time to get the hand back on the wheel

    /// Starts a countdown so the person has time to get their hand back onto
    /// the wheel after tapping Start; actual sampling (and elapsedTime = 0)
    /// only begins once the countdown finishes.
    func start() {
        guard motionManager.isDeviceMotionAvailable, !isRecording, !isCountingDown, !isCalibrating else {
            return
        }
        samples.removeAll()
        sampleCount = 0
        elapsedTime = 0
        startTimestamp = 0

        isCountingDown = true
        countdownRemaining = startCountdownSeconds

        Task { @MainActor in
            WKInterfaceDevice.current().play(.click) // tick for "3"
            while self.countdownRemaining > 1 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                self.countdownRemaining -= 1
                WKInterfaceDevice.current().play(.click) // tick for "2", "1"
            }
            try? await Task.sleep(nanoseconds: 1_000_000_000)

            self.isCountingDown = false
            WKInterfaceDevice.current().play(.start) // distinct buzz: recording has actually begun
            self.beginSampling()
        }
    }

    private func beginSampling() {
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
                attitudeX: motion.attitude.pitch - self.calibrationOffset
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

    /// Clears the finished session's stopwatch/sample count so the watch
    /// screen is ready for a fresh Start. Does not touch calibrationOffset.
    func reset() {
        guard !isRecording, !isCalibrating, !isCountingDown else { return }
        samples.removeAll()
        sampleCount = 0
        elapsedTime = 0
        startTimestamp = 0
    }

    /// Averages raw pitch over `calibrationDuration` seconds and stores the
    /// result as the new zero point. Ask the user to hold their hands at the
    /// wheel's neutral position while this runs. Buzzes the watch on completion.
    func calibrate() {
        guard motionManager.isDeviceMotionAvailable, !isRecording, !isCalibrating, !isCountingDown else { return }
        isCalibrating = true
        calibrationProgress = 0

        var pitchSamples: [Double] = []
        let calibrationStart = Date()

        motionManager.deviceMotionUpdateInterval = 1.0 / sampleRateHz
        queue.qualityOfService = .userInitiated

        motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: queue) { [weak self] motion, error in
            guard let self, let motion else { return }
            pitchSamples.append(motion.attitude.pitch)

            let elapsed = Date().timeIntervalSince(calibrationStart)
            DispatchQueue.main.async {
                self.calibrationProgress = min(elapsed / self.calibrationDuration, 1.0)
            }

            guard elapsed >= self.calibrationDuration else { return }

            self.motionManager.stopDeviceMotionUpdates()
            let average = pitchSamples.reduce(0, +) / Double(pitchSamples.count)

            DispatchQueue.main.async {
                self.calibrationOffset = average
                self.isCalibrating = false
                WKInterfaceDevice.current().play(.success)
            }
        }
    }
}
