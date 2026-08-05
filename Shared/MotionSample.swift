import Foundation

// One CoreMotion reading, captured at ~50 Hz on the Watch.
// Angles are stored in radians (CoreMotion's native unit); use the
// `*Degrees` helpers when displaying.
struct MotionSample: Codable, Identifiable, Hashable {
    var id = UUID()
    
    // Seconds since recording started (this is the chart's X axis).
    let elapsedTime: TimeInterval
    
    // Wrist movement along X axis
    let attitudeX: Double
    
    var attitudeXDegrees: Double { attitudeX * 180 / .pi }

}

/// A full recording, ready to be transferred, stored, or charted.
struct RecordingSession: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    let startDate: Date
    let sampleRateHz: Double
    let samples: [MotionSample]

    var duration: TimeInterval { samples.last?.elapsedTime ?? 0 }

    /// Standard deviation of a given angle across the session.
    /// Lower = steadier hands. This is a simple, explainable stability score;
    /// swap in a different metric (e.g. mean absolute jerk) later if you want.
    var stabilityScore: Double {
        guard !samples.isEmpty else { return 0 }
        let values = samples.map { $0.attitudeXDegrees }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.reduce(0) { $0 + pow($1 - mean, 2) } / Double(values.count)
        return sqrt(variance)
    }
}
