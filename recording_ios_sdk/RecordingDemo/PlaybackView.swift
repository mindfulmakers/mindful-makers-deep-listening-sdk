import AVFoundation
import SwiftUI

struct PlaybackView: View {
    @State private var recordings: [RecordingFile] = []
    @State private var currentlyPlaying: URL?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var playbackDelegate: PlaybackDelegate?

    var body: some View {
        NavigationStack {
            Group {
                if recordings.isEmpty {
                    ContentUnavailableView(
                        "No Recordings",
                        systemImage: "waveform",
                        description: Text("Record some audio to see it here")
                    )
                } else {
                    List {
                        ForEach(recordings) { recording in
                            RecordingRow(
                                recording: recording,
                                isPlaying: currentlyPlaying == recording.url,
                                onPlay: { playRecording(recording) },
                                onStop: stopPlayback
                            )
                        }
                        .onDelete(perform: deleteRecordings)
                    }
                }
            }
            .navigationTitle("Recordings")
            .toolbar {
                if !recordings.isEmpty {
                    EditButton()
                }
            }
            .onAppear {
                loadRecordings()
            }
            .refreshable {
                loadRecordings()
            }
        }
    }

    private func loadRecordings() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: documentsPath,
                includingPropertiesForKeys: [.creationDateKey, .fileSizeKey],
                options: .skipsHiddenFiles
            )

            recordings = files
                .filter { $0.pathExtension.lowercased() == "wav" }
                .compactMap { url -> RecordingFile? in
                    let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
                    let creationDate = attributes?[.creationDate] as? Date ?? Date()
                    let fileSize = attributes?[.size] as? Int64 ?? 0
                    return RecordingFile(url: url, creationDate: creationDate, fileSize: fileSize)
                }
                .sorted { $0.creationDate > $1.creationDate }
        } catch {
            print("Failed to load recordings: \(error)")
        }
    }

    private func playRecording(_ recording: RecordingFile) {
        stopPlayback()

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)

            audioPlayer = try AVAudioPlayer(contentsOf: recording.url)
            playbackDelegate = PlaybackDelegate {
                currentlyPlaying = nil
            }
            audioPlayer?.delegate = playbackDelegate
            audioPlayer?.play()
            currentlyPlaying = recording.url
        } catch {
            print("Playback error: \(error)")
        }
    }

    private func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        playbackDelegate = nil
        currentlyPlaying = nil
    }

    private func deleteRecordings(at offsets: IndexSet) {
        for index in offsets {
            let recording = recordings[index]
            if currentlyPlaying == recording.url {
                stopPlayback()
            }
            try? FileManager.default.removeItem(at: recording.url)
        }
        recordings.remove(atOffsets: offsets)
    }
}

// MARK: - Recording File Model

struct RecordingFile: Identifiable {
    let id = UUID()
    let url: URL
    let creationDate: Date
    let fileSize: Int64

    var name: String {
        url.deletingPathExtension().lastPathComponent
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: creationDate)
    }

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
}

// MARK: - Recording Row View

struct RecordingRow: View {
    let recording: RecordingFile
    let isPlaying: Bool
    let onPlay: () -> Void
    let onStop: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(recording.name)
                    .font(.headline)
                HStack {
                    Text(recording.formattedDate)
                    Text("·")
                    Text(recording.formattedSize)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: isPlaying ? onStop : onPlay) {
                Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                    .font(.title2)
                    .foregroundStyle(isPlaying ? .red : .blue)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Playback Delegate

private class PlaybackDelegate: NSObject, AVAudioPlayerDelegate {
    let onFinish: () -> Void

    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            onFinish()
        }
    }
}

#Preview {
    PlaybackView()
}
