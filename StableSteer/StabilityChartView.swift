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

                VStack(alignment: .leading, spacing: 4) {
                    Text("Stability score (std. dev.): \(String(format: "%.2f", session.stabilityScore))°")
                        .font(.subheadline.bold())
                    Text("Lower is steadier — it's the spread of the X-axis attitude around its average for this session.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle(session.name)
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
