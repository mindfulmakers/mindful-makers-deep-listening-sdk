import Foundation

/// Configuration for audio recording parameters.
public struct AudioRecorderConfiguration: Sendable {
    /// Sample rate in Hz (default 44100)
    public var sampleRate: Double

    /// Number of channels (1 = mono, 2 = stereo)
    public var channels: Int

    /// RMS level below which is considered silence (for silence detection)
    public var silenceThreshold: Float

    /// How long silence must persist to stop recording (seconds)
    public var silenceDuration: TimeInterval

    /// Maximum recording duration (seconds)
    public var timeout: TimeInterval

    /// Minimum recording duration before checking for silence (seconds)
    public var minDuration: TimeInterval

    public init(
        sampleRate: Double = 44100,
        channels: Int = 1,
        silenceThreshold: Float = 0.01,
        silenceDuration: TimeInterval = 2.0,
        timeout: TimeInterval = 300.0,
        minDuration: TimeInterval = 1.0
    ) {
        self.sampleRate = sampleRate
        self.channels = channels
        self.silenceThreshold = silenceThreshold
        self.silenceDuration = silenceDuration
        self.timeout = timeout
        self.minDuration = minDuration
    }
}
