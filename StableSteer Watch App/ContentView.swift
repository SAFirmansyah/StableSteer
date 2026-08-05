import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var recorder = MotionRecorder()
    @ObservedObject private var connectivity = WatchSessionManager.shared

    var body: some View {
        VStack(spacing: 8) {
            Text(timeString(recorder.elapsedTime))
                .font(.system(.title2, design: .monospaced))

            Text("\(recorder.sampleCount) samples")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button(action: toggleRecording) {
                Text(recorder.isRecording ? "Stop" : "Start")
                    .frame(maxWidth: .infinity)
            }
            .tint(recorder.isRecording ? .red : .green)
            .buttonStyle(.borderedProminent)

            if !connectivity.lastTransferStatus.isEmpty {
                Text(connectivity.lastTransferStatus)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }

    private func toggleRecording() {
        if recorder.isRecording {
            let name = "Session \(Date().formatted(date: .abbreviated, time: .shortened))"
            let session = recorder.stop(named: name)
            connectivity.send(session)
        } else {
            recorder.start()
        }
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
