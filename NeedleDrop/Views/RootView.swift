import SwiftUI
import UniformTypeIdentifiers

struct RootView: View {
    @EnvironmentObject private var library: LibraryStore
    @EnvironmentObject private var player: AudioPlayer
    @State private var isShowingImporter = false
    @State private var isShowingPlayer = false

    private var audioTypes: [UTType] {
        [
            UTType(filenameExtension: "mp3") ?? .audio,
            UTType(filenameExtension: "flac") ?? .audio
        ]
    }

    var body: some View {
        TabView {
            NavigationStack {
                LibraryView(isShowingImporter: $isShowingImporter)
            }
            .tabItem { Label("Albums", systemImage: "square.stack") }

            NavigationStack {
                SongsView()
            }
            .tabItem { Label("Songs", systemImage: "music.note.list") }

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("Settings", systemImage: "slider.horizontal.3") }
        }
        .tint(.orange)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if player.currentTrack != nil {
                MiniPlayer {
                    isShowingPlayer = true
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 2)
            }
        }
        .sheet(isPresented: $isShowingPlayer) {
            PlayerView()
        }
        .fileImporter(
            isPresented: $isShowingImporter,
            allowedContentTypes: audioTypes,
            allowsMultipleSelection: true
        ) { result in
            guard case .success(let urls) = result else { return }
            Task { await library.importFiles(urls) }
        }
        .alert(
            "Import",
            isPresented: Binding(
                get: { library.importMessage != nil },
                set: { if !$0 { library.importMessage = nil } }
            )
        ) {
            Button("OK") { library.importMessage = nil }
        } message: {
            Text(library.importMessage ?? "")
        }
    }
}

private struct MiniPlayer: View {
    @EnvironmentObject private var player: AudioPlayer
    let open: () -> Void

    var body: some View {
        Button(action: open) {
            HStack(spacing: 12) {
                ArtworkView(fileName: player.currentTrack?.artworkFileName, cornerRadius: 10)
                    .frame(width: 46, height: 46)
                VStack(alignment: .leading, spacing: 2) {
                    Text(player.currentTrack?.title ?? "")
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Text(player.currentTrack?.artist ?? "")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Button(action: player.togglePlayback) {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title3)
                        .frame(width: 38, height: 38)
                }
                .buttonStyle(PressableButtonStyle())
            }
            .padding(8)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.white.opacity(0.55), lineWidth: 0.5)
            }
        }
        .buttonStyle(PressableButtonStyle())
        .foregroundStyle(.primary)
    }
}
