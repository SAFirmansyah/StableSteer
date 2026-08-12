import SwiftUI
import Charts

/// A session plus the display label already computed for it (circuit + number),
/// carried along so CompareChartView doesn't need to recompute list-ordering logic.
struct ComparisonEntry: Identifiable, Hashable {
    let id = UUID()
    let label: String
    let session: RecordingSession
}

struct ComparisonPair: Hashable {
    let first: ComparisonEntry
    let second: ComparisonEntry
}

struct CompareChartView: View {
    let pair: ComparisonPair

    private let colorA = Color.blue
    private let colorB = Color.orange

    /// Shared Y range across both charts so a swing looks the same size
    /// visually in both — otherwise each chart auto-scaling independently
    /// could make a small wobble in one look as big as a huge swing in the
    /// other just because of axis scaling.
    private var sharedYDomain: ClosedRange<Double> {
        let allValues = (pair.first.session.samples + pair.second.session.samples).map { $0.attitudeXDegrees }
        guard let minValue = allValues.min(), let maxValue = allValues.max(), minValue < maxValue else {
            return -10...10
        }
        let padding = (maxValue - minValue) * 0.1
        return (minValue - padding)...(maxValue + padding)
    }

    /// Shared X range (0 to the longer session's duration) so both charts
    /// line up on the same time scale, making it easy to compare the same
    /// moment across sessions.
    private var sharedXDomain: ClosedRange<Double> {
        let maxDuration = max(pair.first.session.duration, pair.second.session.duration)
        return 0...max(maxDuration, 1)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                chartPanel(entry: pair.first, color: colorA)
                chartPanel(entry: pair.second, color: colorB)
                statsComparison
            }
            .padding(.vertical)
        }
        .navigationTitle("Compare")
    }

    private func chartPanel(entry: ComparisonEntry, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            legendItem(color: color, label: entry.label)

            Chart(entry.session.samples) { sample in
                LineMark(
                    x: .value("Time (s)", sample.elapsedTime),
                    y: .value("Attitude X", sample.attitudeXDegrees)
                )
                .foregroundStyle(color)
                .interpolationMethod(.monotone)
            }
            .chartXScale(domain: sharedXDomain)
            .chartYScale(domain: sharedYDomain)
            .chartXAxisLabel("Time elapsed (s)")
            .chartYAxisLabel("Hand position (°)")
            .frame(height: 180)
        }
        .padding(.horizontal)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(label)
                .font(.subheadline.bold())
                .lineLimit(1)
        }
    }

    private var statsComparison: some View {
        let analysisA = pair.first.session.jerkAnalysis
        let analysisB = pair.second.session.jerkAnalysis

        return VStack(alignment: .leading, spacing: 12) {
            Text("Comparison")
                .font(.subheadline.bold())

            comparisonRow(
                title: "Biggest swing",
                valueA: String(format: "%.0f°", analysisA.maxSwingDegrees),
                valueB: String(format: "%.0f°", analysisB.maxSwingDegrees)
            )
            comparisonRow(
                title: "Jerks",
                valueA: "\(analysisA.jerkEventCount)",
                valueB: "\(analysisB.jerkEventCount)"
            )
            comparisonRow(
                title: "Duration",
                valueA: formattedDuration(pair.first.session.duration),
                valueB: formattedDuration(pair.second.session.duration)
            )
        }
        .padding(.horizontal)
    }

    private func comparisonRow(title: String, valueA: String, valueB: String) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 100, alignment: .leading)
            Text(valueA)
                .font(.subheadline.bold())
                .foregroundStyle(colorA)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(valueB)
                .font(.subheadline.bold())
                .foregroundStyle(colorB)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func formattedDuration(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    NavigationStack {
        CompareChartView(pair: ComparisonPair(
            first: ComparisonEntry(
                label: "Monza Session 1",
                session: RecordingSession(startDate: Date(), sampleRateHz: 50, circuitName: "Monza", samples: [])
            ),
            second: ComparisonEntry(
                label: "Monza Session 2",
                session: RecordingSession(startDate: Date(), sampleRateHz: 50, circuitName: "Monza", samples: [])
            )
        ))
    }
}
