import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            RecordingView()
                .tabItem {
                    Label("Record", systemImage: "mic.fill")
                }

            PlaybackView()
                .tabItem {
                    Label("Recordings", systemImage: "list.bullet")
                }
        }
    }
}

#Preview {
    ContentView()
}
