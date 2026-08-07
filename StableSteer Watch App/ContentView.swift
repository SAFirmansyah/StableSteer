import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var recorder = MotionRecorder()
    @ObservedObject private var connectivity = WatchSessionManager.shared

    private enum ScreenState {
        case idle       // nothing recorded yet, ready to Start or Calibrate
        case recording
        case stopped    // session finished, waiting for Reset
        case calibrating
    }

    private var state: ScreenState {
        if recorder.isCalibrating { return .calibrating }
        if recorder.isRecording { return .recording }
        if recorder.elapsedTime > 0 { return .stopped }
        return .idle
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(timeString(recorder.elapsedTime))
                .font(.system(.title2, design: .monospaced))

            Text("\(recorder.sampleCount) samples")
                .font(.caption)
                .foregroundStyle(.secondary)

            switch state {
            case .idle:
                Button(action: recorder.start) {
                    Text("Start")
                        .frame(maxWidth: .infinity)
                }
                .tint(.green)
                .buttonStyle(.borderedProminent)

                Button(action: recorder.calibrate) {
                    Text("Calibrate")
                        .frame(maxWidth: .infinity)
                }
                .tint(.blue)
                .buttonStyle(.bordered)

            case .recording:
                Button(action: stopRecording) {
                    Text("Stop")
                        .frame(maxWidth: .infinity)
                }
                .tint(.red)
                .buttonStyle(.borderedProminent)

            case .stopped:
                Button(action: recorder.reset) {
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

            if !connectivity.lastTransferStatus.isEmpty {
                Text(connectivity.lastTransferStatus)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }

    private func stopRecording() {
        let name = "Session \(Date().formatted(date: .abbreviated, time: .shortened))"
        let session = recorder.stop(named: name)
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
