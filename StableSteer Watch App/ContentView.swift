import SwiftUI

struct ContentView: View {
    @StateObject private var recorder = MotionRecorder()
    @ObservedObject private var connectivity = WatchSessionManager.shared
    @ObservedObject private var circuitSettings = CircuitSettings.shared

    private enum ScreenState {
        case idle          // nothing recorded yet, ready to Start or Calibrate
        case countingDown  // Start was tapped, waiting for the hand to get back on the wheel
        case recording
        case stopped       // session finished, waiting for Reset
        case calibrating
    }

    private var state: ScreenState {
        if recorder.isCountingDown { return .countingDown }
        if recorder.isCalibrating { return .calibrating }
        if recorder.isRecording { return .recording }
        if recorder.elapsedTime > 0 { return .stopped }
        return .idle
    }

    /// Only safe to change circuit when nothing is actively happening —
    /// switching mid-recording would be confusing.
    private var canChangeCircuit: Bool {
        state == .idle || state == .stopped
    }

    var body: some View {
        NavigationStack {
            Group {
                if state == .countingDown {
                    countdownView
                } else {
                    stopwatchView
                }
            }
            .padding()
            .padding(.top, 12)
            .navigationTitle(circuitSettings.selectedCircuit.rawValue)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        CircuitSettingsView()
                    } label: {
                        Image(systemName: "flag.checkered")
                    }
                    .disabled(!canChangeCircuit)
                }
            }
        }
    }

    private var countdownView: some View {
        VStack(spacing: 8) {
            Text("\(recorder.countdownRemaining)")
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundStyle(.green)
            Text("Get your hand back on the wheel…")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var stopwatchView: some View {
        VStack(spacing: 8) {
            Text(timeString(recorder.elapsedTime))
                .font(.system(.title2, design: .monospaced))

            Text("\(recorder.sampleCount) samples")
                .font(.caption)
                .foregroundStyle(.secondary)

            switch state {
            case .idle:
                Button(action: startRecording) {
                    Text("Start")
                        .frame(maxWidth: .infinity)
                }
                .tint(.green)
                .buttonStyle(.borderedProminent)

                Button(action: calibrate) {
                    Text("Calibrate")
                        .frame(maxWidth: .infinity)
                }
                .tint(.blue)
                .foregroundStyle(Color(.white))
                .buttonStyle(.borderedProminent)

            case .countingDown:
                EmptyView() // handled by countdownView above

            case .recording:
                Button(action: stopRecording) {
                    Text("Stop")
                        .frame(maxWidth: .infinity)
                }
                .tint(.red)
                .buttonStyle(.borderedProminent)

            case .stopped:
                Button(action: resetSession) {
                    Text("Reset")
                        .frame(maxWidth: .infinity)
                }
                .tint(.orange)
                .buttonStyle(.borderedProminent)

            case .calibrating:
                ProgressView(value: recorder.calibrationProgress)
                    .tint(.blue)
                Text("Hold hands at neutral wheel position…")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Only relevant right after a Stop, while a transfer may be in
            // flight — hidden in every other state so a stale message can't
            // linger into the next recording or calibration.
            if state == .stopped, !connectivity.lastTransferStatus.isEmpty {
                Text(connectivity.lastTransferStatus)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private func startRecording() {
        connectivity.lastTransferStatus = ""
        recorder.start()
    }

    private func calibrate() {
        connectivity.lastTransferStatus = ""
        recorder.calibrate()
    }

    private func resetSession() {
        connectivity.lastTransferStatus = ""
        recorder.reset()
    }

    private func stopRecording() {
        let name = "Session \(Date().formatted(date: .abbreviated, time: .shortened))"
        let session = recorder.stop(named: name, circuit: circuitSettings.selectedCircuit)
        connectivity.send(session)
    }

    private func timeString(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        let tenths = Int((interval.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d:%02d.%d", minutes, seconds, tenths)
    }
}

#Preview {
    ContentView()
}
