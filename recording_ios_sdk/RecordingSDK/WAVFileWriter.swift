import AVFoundation
import Foundation

/// Utility for writing audio data to WAV files.
public struct WAVFileWriter: Sendable {
    /// Save audio samples to a WAV file.
    /// - Parameters:
    ///   - audio: Audio samples as Float array
    ///   - url: Destination file URL
    ///   - sampleRate: Sample rate of the audio
    ///   - channels: Number of audio channels
    public static func write(
        audio: [Float],
        to url: URL,
        sampleRate: Double,
        channels: Int
    ) throws {
        guard !audio.isEmpty else {
            throw AudioRecorderError.saveFailed("No audio data to save")
        }

        let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: AVAudioChannelCount(channels),
            interleaved: false
        )

        guard let format = format else {
            throw AudioRecorderError.saveFailed("Failed to create audio format")
        }

        let frameCount = AVAudioFrameCount(audio.count / channels)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            throw AudioRecorderError.saveFailed("Failed to create audio buffer")
        }

        buffer.frameLength = frameCount

        // Copy audio data to buffer
        if let channelData = buffer.floatChannelData {
            for channel in 0..<channels {
                for frame in 0..<Int(frameCount) {
                    let sampleIndex = frame * channels + channel
                    if sampleIndex < audio.count {
                        channelData[channel][frame] = audio[sampleIndex]
                    }
                }
            }
        }

        // Write to file
        let audioFile: AVAudioFile
        do {
            audioFile = try AVAudioFile(
                forWriting: url,
                settings: format.settings,
                commonFormat: .pcmFormatFloat32,
                interleaved: false
            )
        } catch {
            throw AudioRecorderError.saveFailed("Failed to create audio file: \(error.localizedDescription)")
        }

        do {
            try audioFile.write(from: buffer)
        } catch {
            throw AudioRecorderError.saveFailed("Failed to write audio data: \(error.localizedDescription)")
        }
    }
}
