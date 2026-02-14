import Foundation

/// Errors that can occur during audio recording.
public enum AudioRecorderError: Error, LocalizedError, Equatable {
    case alreadyRecording
    case notRecording
    case audioEngineSetupFailed(String)
    case microphonePermissionDenied
    case noInputAvailable
    case saveFailed(String)

    public var errorDescription: String? {
        switch self {
        case .alreadyRecording:
            return "Already recording"
        case .notRecording:
            return "Not currently recording"
        case .audioEngineSetupFailed(let reason):
            return "Audio engine setup failed: \(reason)"
        case .microphonePermissionDenied:
            return "Microphone permission denied"
        case .noInputAvailable:
            return "No audio input available"
        case .saveFailed(let reason):
            return "Failed to save recording: \(reason)"
        }
    }
}
