import SwiftUI
import Charts

struct StabilityChartView: View {
    let session: RecordingSession

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Chart(session.samples) { sample in
                    LineMark(
                        x: .value("Time (s)", sample.elapsedTime),
                        y: .value("Attitude X", sample.attitudeXDegrees)
                    )
                    .interpolationMethod(.monotone)
                }
                .chartXAxisLabel("Time elapsed (s)")
                .chartYAxisLabel("Hand position (°)")
                .frame(height: 260)
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    let analysis = session.jerkAnalysis

                    HStack {
                        statBlock(
                            value: String(format: "%.0f°", analysis.maxSwingDegrees),
                            label: "Biggest swing"
                        )
                        Divider().frame(height: 32)
                        statBlock(
                            value: "\(analysis.jerkEventCount)",
                            label: analysis.jerkEventCount == 1 ? "Jerk" : "Jerks"
                        )
                    }

                    Text("A jerk is a swing of \(Int(RecordingSession.jerkThresholdDegrees))° or more within \(String(format: "%.1f", RecordingSession.jerkWindowDuration))s — the kind of sudden hand movement that shifts a car's weight aggressively enough to risk a slide.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle(session.name)
    }

    private func statBlock(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value)
                .font(.title3.bold())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        StabilityChartView(session: RecordingSession(
            name: "Preview",
            startDate: Date(),
            sampleRateHz: 50,
            samples: []
        ))
    }
}
