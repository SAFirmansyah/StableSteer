import Foundation

/// One CoreMotion reading, captured at ~50 Hz on the Watch.
/// Angles are stored in radians (CoreMotion's native unit); use the
/// `*Degrees` helpers when displaying.
struct MotionSample: Codable, Identifiable, Hashable {
    var id = UUID()

    /// Seconds since recording started (this is the chart's X axis).
    let elapsedTime: TimeInterval

    /// Attitude around the watch's X axis (CoreMotion calls this "pitch").
    /// This is the "hand position" signal — how far the wrist has rolled
    /// as it turns the wheel.
    let attitudeX: Double

    var attitudeXDegrees: Double { attitudeX * 180 / .pi }
}

/// A full recording, ready to be transferred, stored, or charted.
struct RecordingSession: Codable, Identifiable, Hashable {
    var id = UUID()
    /// nil unless the person has explicitly renamed this session on the
    /// phone; when nil, the app shows an auto-generated "<circuit> Session
    /// <n>" title instead. See PhoneSessionManager.displayTitle(for:).
    var customName: String?
    let startDate: Date
    let sampleRateHz: Double
    /// Raw value of the Circuit selected on the watch when this was recorded.
    let circuitName: String
    let samples: [MotionSample]

    var duration: TimeInterval { samples.last?.elapsedTime ?? 0 }

    /// A swing this large, happening within jerkWindowDuration, counts as
    /// a dangerous jerk — the kind of sudden hand movement that shifts a
    /// car's weight aggressively enough to risk a slide.
    static let jerkThresholdDegrees: Double = 30
    /// "Split second" — how fast the swing has to happen to count.
    static let jerkWindowDuration: TimeInterval = 0.3

    struct JerkAnalysis {
        /// The single largest angle swing found within any jerkWindowDuration
        /// window across the whole session.
        let maxSwingDegrees: Double
        /// How many separate times the swing crossed jerkThresholdDegrees.
        /// Consecutive samples over threshold count as one event, not many.
        let jerkEventCount: Int
    }

    /// Scans the session with a sliding time window and looks for rapid,
    /// large-angle swings (e.g. +30° to -20° within 0.3s) rather than
    /// averaging everything together the way a standard deviation would —
    /// a slow drift and a violent snap can share the same std. dev., but
    /// only the snap matters for weight transfer.
    var jerkAnalysis: JerkAnalysis {
        guard samples.count > 1 else { return JerkAnalysis(maxSwingDegrees: 0, jerkEventCount: 0) }

        var maxSwing: Double = 0
        var eventCount = 0
        var inEvent = false
        var left = 0

        for right in samples.indices {
            while samples[right].elapsedTime - samples[left].elapsedTime > Self.jerkWindowDuration {
                left += 1
            }

            var windowMax = samples[left].attitudeXDegrees
            var windowMin = windowMax
            for i in left...right {
                let value = samples[i].attitudeXDegrees
                windowMax = max(windowMax, value)
                windowMin = min(windowMin, value)
            }

            let swing = windowMax - windowMin
            maxSwing = max(maxSwing, swing)

            if swing >= Self.jerkThresholdDegrees {
                if !inEvent {
                    eventCount += 1
                    inEvent = true
                }
            } else {
                inEvent = false
            }
        }

        return JerkAnalysis(maxSwingDegrees: maxSwing, jerkEventCount: eventCount)
    }
}
