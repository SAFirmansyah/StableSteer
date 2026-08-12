import SwiftUI
import Charts

struct StabilityChartView: View {
    @State private var session: RecordingSession
    @State private var selectedSample: MotionSample?
    @State private var isRenaming = false
    @State private var draftName = ""

    @ObservedObject private var manager = PhoneSessionManager.shared

    init(session: RecordingSession) {
        _session = State(initialValue: session)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Chart {
                    ForEach(session.samples) { sample in
                        LineMark(
                            x: .value("Time (s)", sample.elapsedTime),
                            y: .value("Attitude X", sample.attitudeXDegrees)
                        )
                        .interpolationMethod(.monotone)
                    }

                    if let selectedSample {
                        RuleMark(x: .value("Time (s)", selectedSample.elapsedTime))
                            .foregroundStyle(.secondary.opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))

                        PointMark(
                            x: .value("Time (s)", selectedSample.elapsedTime),
                            y: .value("Attitude X", selectedSample.attitudeXDegrees)
                        )
                        .foregroundStyle(.blue)
                        .symbolSize(80)
                        .annotation(position: .top, overflowResolution: .init(x: .fit, y: .fit)) {
                            VStack(spacing: 2) {
                                Text(String(format: "%.2fs", selectedSample.elapsedTime))
                                    .font(.caption2.bold())
                                Text(String(format: "%.1f°", selectedSample.attitudeXDegrees))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(6)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }
                .chartXAxisLabel("Time elapsed (s)")
                .chartYAxisLabel("Hand position (°)")
                .frame(height: 260)
                .padding(.horizontal)
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        updateSelection(at: value.location, proxy: proxy, geometry: geometry)
                                    }
                                    .onEnded { _ in
                                        selectedSample = nil
                                    }
                            )
                    }
                }

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
        .navigationTitle(manager.displayTitle(for: session))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    draftName = session.customName ?? ""
                    isRenaming = true
                } label: {
                    Image(systemName: "pencil")
                }
            }
        }
        .alert("Rename Session", isPresented: $isRenaming) {
            TextField("Session name", text: $draftName)
            Button("Cancel", role: .cancel) {}
            if session.customName != nil {
                Button("Reset to Automatic", role: .destructive) {
                    session.customName = nil
                    manager.rename(sessionID: session.id, to: "")
                }
            }
            Button("Save") {
                let trimmed = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
                session.customName = trimmed.isEmpty ? nil : trimmed
                manager.rename(sessionID: session.id, to: trimmed)
            }
        } message: {
            Text("Leave blank to use the automatic \"circuit + number\" title.")
        }
    }

    /// Converts a drag location on the chart into the nearest recorded sample.
    private func updateSelection(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
        guard let anchor = proxy.plotFrame else { return }
        let plotFrame = geometry[anchor]
        guard plotFrame.contains(location) else { return }

        let xInPlot = location.x - plotFrame.origin.x
        guard let time: Double = proxy.value(atX: xInPlot) else { return }

        selectedSample = session.samples.min { a, b in
            abs(a.elapsedTime - time) < abs(b.elapsedTime - time)
        }
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
            startDate: Date(),
            sampleRateHz: 50,
            circuitName: Circuit.monza.rawValue,
            samples: []
        ))
    }
}
