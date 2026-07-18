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
        .tint(AppTheme.ink)
        .toolbarBackground(AppTheme.paper, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if player.currentTrack != nil {
                MiniPlayer {
                    isShowingPlayer = true
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 4)
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
        HStack(spacing: 8) {
            Button(action: open) {
                HStack(spacing: 12) {
                    ArtworkView(fileName: player.currentTrack?.artworkFileName, cornerRadius: 5)
                        .frame(width: 44, height: 44)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(player.currentTrack?.title ?? "")
                            .font(.subheadline.weight(.bold))
                            .lineLimit(1)
                        Text(player.currentTrack?.artist ?? "")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.58))
                            .lineLimit(1)
                    }
                    Spacer()
                }
            }
            .buttonStyle(PressableButtonStyle())
            Button(action: player.togglePlayback) {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: 40, height: 40)
                    .background(
                        LinearGradient(colors: [.white, Color(white: 0.82)], startPoint: .top, endPoint: .bottom),
                        in: Circle()
                    )
                    .foregroundStyle(AppTheme.ink)
                    .shadow(color: .black.opacity(0.35), radius: 3, y: 2)
            }
            .buttonStyle(PressableButtonStyle())
        }
        .padding(8)
        .background(
            LinearGradient(colors: [Color(white: 0.16), Color(white: 0.04)], startPoint: .top, endPoint: .bottom),
            in: RoundedRectangle(cornerRadius: 13, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 13)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        }
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.18), radius: 14, y: 7)
    }
}
