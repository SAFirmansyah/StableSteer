//
//  ComparisonEntry.swift
//  StableSteer
//
//  Created by Satria Adi Firmansyah on 12/08/26.
//


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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                legend

                Chart {
                    ForEach(pair.first.session.samples) { sample in
                        LineMark(
                            x: .value("Time (s)", sample.elapsedTime),
                            y: .value("Attitude X", sample.attitudeXDegrees)
                        )
                        .foregroundStyle(colorA)
                        .interpolationMethod(.monotone)
                    }
                    ForEach(pair.second.session.samples) { sample in
                        LineMark(
                            x: .value("Time (s)", sample.elapsedTime),
                            y: .value("Attitude X", sample.attitudeXDegrees)
                        )
                        .foregroundStyle(colorB)
                        .interpolationMethod(.monotone)
                    }
                }
                .chartXAxisLabel("Time elapsed (s)")
                .chartYAxisLabel("Hand position (°)")
                .frame(height: 280)
                .padding(.horizontal)

                statsComparison
            }
            .padding(.vertical)
        }
        .navigationTitle("Compare")
    }

    private var legend: some View {
        HStack(spacing: 16) {
            legendItem(color: colorA, label: pair.first.label)
            legendItem(color: colorB, label: pair.second.label)
        }
        .padding(.horizontal)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(label)
                .font(.caption)
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
                session: RecordingSession(name: "A", startDate: Date(), sampleRateHz: 50, circuitName: "Monza", samples: [])
            ),
            second: ComparisonEntry(
                label: "Monza Session 2",
                session: RecordingSession(name: "B", startDate: Date(), sampleRateHz: 50, circuitName: "Monza", samples: [])
            )
        ))
    }
}