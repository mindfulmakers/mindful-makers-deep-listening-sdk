import Accelerate
import AVFoundation
import Foundation

/// Audio recorder for voice journaling and soundscape capture.
///
/// Provides real-time audio capture with level monitoring, silence detection,
/// and WAV file export capabilities.
@MainActor
public final class AudioRecorder: ObservableObject {
    // MARK: - Published Properties

    /// Whether the recorder is currently capturing audio
    @Published public private(set) var isRecording = false

    /// Current input level (0.0 = silence, 1.0 = max)
    @Published public private(set) var currentLevel: Float = 0

    /// Duration of current recording in seconds
    @Published public private(set) var recordingDuration: TimeInterval = 0

    // MARK: - Private Properties

    private let configuration: AudioRecorderConfiguration
    private var audioEngine: AVAudioEngine?
    private var audioBuffer: [Float] = []
    private var recordingStartTime: Date?
    private var durationTimer: Timer?

    // Silence detection state
    private var silenceBlockCount = 0
    private var totalBlockCount = 0
    private let blockDuration: TimeInterval = 0.1 // 100ms blocks

    // Continuation for async methods
    private var silenceDetectionContinuation: CheckedContinuation<[Float], Error>?
    private var fixedDurationContinuation: CheckedContinuation<[Float], Error>?
    private var targetSampleCount: Int = 0

    // MARK: - Initialization

    /// Initialize recorder with configuration.
    /// - Parameter configuration: Recording parameters
    public init(configuration: AudioRecorderConfiguration = AudioRecorderConfiguration()) {
        self.configuration = configuration
    }

    // MARK: - Public Methods

    /// Request microphone permission.
    /// - Returns: Whether permission was granted
    public func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    /// Record audio for a fixed duration.
    /// - Parameter duration: Recording duration in seconds
    /// - Returns: Recorded audio samples
    public func recordAudio(duration: TimeInterval) async throws -> [Float] {
        guard !isRecording else {
            throw AudioRecorderError.alreadyRecording
        }

        try await setupAudioSession()
        try setupAudioEngine()

        targetSampleCount = Int(duration * configuration.sampleRate)

        return try await withCheckedThrowingContinuation { continuation in
            self.fixedDurationContinuation = continuation
            startCapture(mode: .fixedDuration)
        }
    }

    /// Record until silence is detected.
    /// - Returns: Recorded audio samples
    public func recordUntilSilence() async throws -> [Float] {
        guard !isRecording else {
            throw AudioRecorderError.alreadyRecording
        }

        try await setupAudioSession()
        try setupAudioEngine()

        return try await withCheckedThrowingContinuation { continuation in
            self.silenceDetectionContinuation = continuation
            startCapture(mode: .untilSilence)
        }
    }

    /// Start continuous recording (non-blocking).
    /// Call `stopRecording()` to finish and get the audio.
    public func startRecording() async throws {
        guard !isRecording else {
            throw AudioRecorderError.alreadyRecording
        }

        try await setupAudioSession()
        try setupAudioEngine()
        startCapture(mode: .manual)
    }

    /// Stop recording and return captured audio.
    /// - Returns: Recorded audio samples
    public func stopRecording() throws -> [Float] {
        guard isRecording else {
            throw AudioRecorderError.notRecording
        }

        stopCapture()
        let result = audioBuffer
        audioBuffer = []
        return result
    }

    /// Save recorded audio to a WAV file.
    /// - Parameters:
    ///   - audio: Audio samples to save
    ///   - url: Destination file URL
    public func saveRecording(_ audio: [Float], to url: URL) throws {
        try WAVFileWriter.write(
            audio: audio,
            to: url,
            sampleRate: configuration.sampleRate,
            channels: configuration.channels
        )
    }

    // MARK: - Private Methods

    private func setupAudioSession() async throws {
        let session = AVAudioSession.sharedInstance()

        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
        } catch {
            throw AudioRecorderError.audioEngineSetupFailed(error.localizedDescription)
        }

        // Check permission
        let status = AVAudioApplication.shared.recordPermission
        if status == .denied {
            throw AudioRecorderError.microphonePermissionDenied
        }
    }

    private func setupAudioEngine() throws {
        audioEngine = AVAudioEngine()

        guard let engine = audioEngine else {
            throw AudioRecorderError.audioEngineSetupFailed("Failed to create audio engine")
        }

        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        guard inputFormat.channelCount > 0 else {
            throw AudioRecorderError.noInputAvailable
        }
    }

    private enum RecordingMode {
        case fixedDuration
        case untilSilence
        case manual
    }

    private func startCapture(mode: RecordingMode) {
        guard let engine = audioEngine else { return }

        audioBuffer = []
        silenceBlockCount = 0
        totalBlockCount = 0
        isRecording = true
        recordingStartTime = Date()

        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        let blockSize = AVAudioFrameCount(blockDuration * inputFormat.sampleRate)

        let silenceBlocksNeeded = Int(configuration.silenceDuration / blockDuration)
        let minBlocks = Int(configuration.minDuration / blockDuration)
        let maxBlocks = Int(configuration.timeout / blockDuration)

        inputNode.installTap(onBus: 0, bufferSize: blockSize, format: inputFormat) { [weak self] buffer, _ in
            Task { @MainActor in
                guard let self = self, self.isRecording else { return }

                // Extract samples from buffer
                let samples = self.extractSamples(from: buffer)
                self.audioBuffer.append(contentsOf: samples)
                self.totalBlockCount += 1

                // Calculate RMS level using Accelerate
                let rms = self.calculateRMS(samples)
                self.currentLevel = min(1.0, rms * 10) // Scale for visibility

                switch mode {
                case .fixedDuration:
                    if self.audioBuffer.count >= self.targetSampleCount {
                        let result = Array(self.audioBuffer.prefix(self.targetSampleCount))
                        self.stopCapture()
                        self.fixedDurationContinuation?.resume(returning: result)
                        self.fixedDurationContinuation = nil
                    }

                case .untilSilence:
                    // Check for silence
                    if rms < self.configuration.silenceThreshold && self.totalBlockCount >= minBlocks {
                        self.silenceBlockCount += 1
                    } else {
                        self.silenceBlockCount = 0
                    }

                    // Stop if silence detected or timeout
                    if self.silenceBlockCount >= silenceBlocksNeeded || self.totalBlockCount >= maxBlocks {
                        let result = self.audioBuffer
                        self.stopCapture()
                        self.silenceDetectionContinuation?.resume(returning: result)
                        self.silenceDetectionContinuation = nil
                    }

                case .manual:
                    // Just keep recording until stopRecording() is called
                    break
                }
            }
        }

        do {
            try engine.start()
        } catch {
            isRecording = false
            fixedDurationContinuation?.resume(throwing: AudioRecorderError.audioEngineSetupFailed(error.localizedDescription))
            silenceDetectionContinuation?.resume(throwing: AudioRecorderError.audioEngineSetupFailed(error.localizedDescription))
            fixedDurationContinuation = nil
            silenceDetectionContinuation = nil
        }

        // Start duration timer
        durationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, let startTime = self.recordingStartTime else { return }
                self.recordingDuration = Date().timeIntervalSince(startTime)
            }
        }
    }

    private func stopCapture() {
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        isRecording = false
        currentLevel = 0
        durationTimer?.invalidate()
        durationTimer = nil
        recordingDuration = 0
    }

    private func extractSamples(from buffer: AVAudioPCMBuffer) -> [Float] {
        guard let channelData = buffer.floatChannelData else { return [] }

        let frameLength = Int(buffer.frameLength)
        var samples = [Float](repeating: 0, count: frameLength)

        // Average channels if stereo, otherwise just copy mono
        let channelCount = Int(buffer.format.channelCount)
        if channelCount == 1 {
            memcpy(&samples, channelData[0], frameLength * MemoryLayout<Float>.size)
        } else {
            for i in 0..<frameLength {
                var sum: Float = 0
                for ch in 0..<channelCount {
                    sum += channelData[ch][i]
                }
                samples[i] = sum / Float(channelCount)
            }
        }

        return samples
    }

    private func calculateRMS(_ samples: [Float]) -> Float {
        guard !samples.isEmpty else { return 0 }

        var rms: Float = 0
        vDSP_rmsqv(samples, 1, &rms, vDSP_Length(samples.count))
        return rms
    }
}
