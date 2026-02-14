import RecordingSDK
import Testing

@Suite("AudioRecorder Tests")
struct AudioRecorderTests {
    // MARK: - Configuration Tests

    @Test("Default configuration has correct values")
    func defaultConfiguration() {
        let config = AudioRecorderConfiguration()

        #expect(config.sampleRate == 44100)
        #expect(config.channels == 1)
        #expect(config.silenceThreshold == 0.01)
        #expect(config.silenceDuration == 2.0)
        #expect(config.timeout == 300.0)
        #expect(config.minDuration == 1.0)
    }

    @Test("Custom configuration preserves values")
    func customConfiguration() {
        let config = AudioRecorderConfiguration(
            sampleRate: 48000,
            channels: 2,
            silenceThreshold: 0.05,
            silenceDuration: 3.0,
            timeout: 120.0,
            minDuration: 2.0
        )

        #expect(config.sampleRate == 48000)
        #expect(config.channels == 2)
        #expect(config.silenceThreshold == 0.05)
        #expect(config.silenceDuration == 3.0)
        #expect(config.timeout == 120.0)
        #expect(config.minDuration == 2.0)
    }

    // MARK: - Error Tests

    @Test("Error descriptions are correct")
    func errorDescriptions() {
        let alreadyRecording = AudioRecorderError.alreadyRecording
        #expect(alreadyRecording.localizedDescription == "Already recording")

        let notRecording = AudioRecorderError.notRecording
        #expect(notRecording.localizedDescription == "Not currently recording")

        let setupFailed = AudioRecorderError.audioEngineSetupFailed("Test error")
        #expect(setupFailed.localizedDescription == "Audio engine setup failed: Test error")

        let permissionDenied = AudioRecorderError.microphonePermissionDenied
        #expect(permissionDenied.localizedDescription == "Microphone permission denied")

        let noInput = AudioRecorderError.noInputAvailable
        #expect(noInput.localizedDescription == "No audio input available")

        let saveFailed = AudioRecorderError.saveFailed("Test save error")
        #expect(saveFailed.localizedDescription == "Failed to save recording: Test save error")
    }

    // MARK: - Recorder State Tests

    @Test("Recorder initializes with correct state")
    @MainActor
    func recorderInitialState() {
        let recorder = AudioRecorder()

        #expect(!recorder.isRecording)
        #expect(recorder.currentLevel == 0)
        #expect(recorder.recordingDuration == 0)
    }

    @Test("Recorder with custom configuration initializes correctly")
    @MainActor
    func recorderCustomConfig() {
        let config = AudioRecorderConfiguration(sampleRate: 48000, channels: 2)
        let recorder = AudioRecorder(configuration: config)

        #expect(!recorder.isRecording)
    }

    @Test("Stop recording throws when not recording")
    @MainActor
    func stopWithoutStartThrows() {
        let recorder = AudioRecorder()

        #expect(throws: AudioRecorderError.notRecording) {
            _ = try recorder.stopRecording()
        }
    }
}
