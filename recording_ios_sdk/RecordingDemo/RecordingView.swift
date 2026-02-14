import RecordingSDK
import SwiftUI

struct RecordingView: View {
    @StateObject private var recorder = AudioRecorder()
    @State private var recordingMode: RecordingMode = .manual
    @State private var fixedDuration: Double = 10
    @State private var statusMessage = "Ready to record"
    @State private var hasPermission = false
    @State private var showingPermissionAlert = false

    enum RecordingMode: String, CaseIterable {
        case manual = "Manual"
        case fixedDuration = "Fixed Duration"
        case untilSilence = "Until Silence"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Mode picker
                Picker("Recording Mode", selection: $recordingMode) {
                    ForEach(RecordingMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Duration slider for fixed duration mode
                if recordingMode == .fixedDuration {
                    VStack {
                        Text("Duration: \(Int(fixedDuration)) seconds")
                            .font(.subheadline)
                        Slider(value: $fixedDuration, in: 1...60, step: 1)
                    }
                    .padding(.horizontal)
                }

                Spacer()

                // Level meter
                LevelMeterView(level: recorder.currentLevel)
                    .frame(height: 20)
                    .padding(.horizontal, 40)

                // Recording timer
                if recorder.isRecording {
                    Text(formatDuration(recorder.recordingDuration))
                        .font(.system(size: 48, weight: .light, design: .monospaced))
                        .foregroundStyle(.red)
                }

                // Status message
                Text(statusMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer()

                // Record/Stop button
                Button(action: toggleRecording) {
                    ZStack {
                        Circle()
                            .fill(recorder.isRecording ? .red : .blue)
                            .frame(width: 80, height: 80)

                        if recorder.isRecording {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.white)
                                .frame(width: 30, height: 30)
                        } else {
                            Circle()
                                .fill(.white)
                                .frame(width: 60, height: 60)
                            Circle()
                                .fill(.red)
                                .frame(width: 56, height: 56)
                        }
                    }
                }
                .disabled(!hasPermission)

                Spacer()
            }
            .navigationTitle("Record")
            .task {
                hasPermission = await recorder.requestPermission()
                if !hasPermission {
                    showingPermissionAlert = true
                }
            }
            .alert("Microphone Access Required", isPresented: $showingPermissionAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Please enable microphone access in Settings to use this app.")
            }
        }
    }

    private func toggleRecording() {
        if recorder.isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        Task {
            do {
                switch recordingMode {
                case .manual:
                    try await recorder.startRecording()
                    statusMessage = "Recording... Tap to stop"

                case .fixedDuration:
                    statusMessage = "Recording for \(Int(fixedDuration)) seconds..."
                    let audio = try await recorder.recordAudio(duration: fixedDuration)
                    await saveRecording(audio)

                case .untilSilence:
                    statusMessage = "Recording... Will stop after silence"
                    let audio = try await recorder.recordUntilSilence()
                    await saveRecording(audio)
                }
            } catch {
                statusMessage = "Error: \(error.localizedDescription)"
            }
        }
    }

    private func stopRecording() {
        do {
            let audio = try recorder.stopRecording()
            Task {
                await saveRecording(audio)
            }
        } catch {
            statusMessage = "Error: \(error.localizedDescription)"
        }
    }

    private func saveRecording(_ audio: [Float]) async {
        guard !audio.isEmpty else {
            statusMessage = "No audio recorded"
            return
        }

        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let filename = "recording_\(dateFormatter.string(from: Date())).wav"
        let fileURL = documentsPath.appendingPathComponent(filename)

        do {
            try recorder.saveRecording(audio, to: fileURL)
            statusMessage = "Saved: \(filename)"
        } catch {
            statusMessage = "Save error: \(error.localizedDescription)"
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        let tenths = Int((duration.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d:%02d.%d", minutes, seconds, tenths)
    }
}

// MARK: - Level Meter View

struct LevelMeterView: View {
    let level: Float

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))

                RoundedRectangle(cornerRadius: 4)
                    .fill(levelColor)
                    .frame(width: geometry.size.width * CGFloat(level))
                    .animation(.linear(duration: 0.05), value: level)
            }
        }
    }

    private var levelColor: Color {
        if level > 0.8 {
            return .red
        } else if level > 0.5 {
            return .yellow
        } else {
            return .green
        }
    }
}

#Preview {
    RecordingView()
}
