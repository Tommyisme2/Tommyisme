import SwiftUI

struct PlayerView: View {
    @EnvironmentObject private var player: AudioPlayer
    @EnvironmentObject private var library: LibraryStore
    @Environment(\.dismiss) private var dismiss
    @State private var scrubValue: Double = 0
    @State private var isScrubbing = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.canvas
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        SpeakerGrille(rows: 4, columns: 13, dotSize: 4.5)
                            .padding(.top, 12)
                        recordDeck
                        metadata
                        progress
                        controls
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 28)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: dismiss.callAsFunction) {
                        Image(systemName: "arrow.down")
                            .fontWeight(.bold)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("PLAYING NOW")
                        .font(.caption2.bold())
                        .tracking(1.6)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if let track = player.currentTrack {
                            library.toggleFavorite(track)
                        }
                    } label: {
                        Image(systemName: player.currentTrack?.isFavorite == true ? "heart.fill" : "heart")
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .tint(AppTheme.ink)
            .onChange(of: player.elapsed) { _, value in
                if !isScrubbing { scrubValue = value }
            }
        }
    }

    private var recordDeck: some View {
        ZStack {
            VinylRecordView(artworkFileName: player.currentTrack?.artworkFileName)
                .frame(width: 230, height: 230)
                .offset(x: 58)
                .rotationEffect(.degrees(player.isPlaying ? 360 : 0))
                .animation(
                    player.isPlaying
                        ? .linear(duration: 8).repeatForever(autoreverses: false)
                        : .default,
                    value: player.isPlaying
                )
            ArtworkView(fileName: player.currentTrack?.artworkFileName, cornerRadius: 8)
                .frame(width: 230, height: 230)
                .offset(x: -42)
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.white.opacity(0.30), lineWidth: 0.7)
                }
                .shadow(color: .black.opacity(0.22), radius: 12, y: 8)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 260)
        .padding(.vertical, 10)
        .background(
            LinearGradient(colors: [AppTheme.paper, AppTheme.raised], startPoint: .top, endPoint: .bottom),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(AppTheme.panelStroke, lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
    }

    private var metadata: some View {
        VStack(spacing: 6) {
            Text(player.currentTrack?.artist.uppercased() ?? "")
                .font(.caption2.bold())
                .tracking(1.4)
                .foregroundStyle(AppTheme.muted)
            Text(player.currentTrack?.title ?? "Nothing Playing")
                .font(.system(size: 31, weight: .bold, design: .default))
                .multilineTextAlignment(.center)
            Text(player.currentTrack?.album ?? "")
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted)
        }
        .frame(maxWidth: .infinity)
    }

    private var progress: some View {
        VStack(spacing: 7) {
            Slider(
                value: $scrubValue,
                in: 0...max(player.duration, 1),
                onEditingChanged: { editing in
                    isScrubbing = editing
                    if !editing { player.seek(to: scrubValue) }
                }
            )
            .tint(AppTheme.orange)
            HStack {
                Text(scrubValue.clockString)
                Spacer()
                Text(player.duration.clockString)
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(AppTheme.muted)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppTheme.paper, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.panelStroke, lineWidth: 1)
        }
    }

    private var controls: some View {
        HStack(spacing: 18) {
            Button(action: player.previous) {
                Image(systemName: "backward.fill")
                    .frame(width: 62, height: 62)
                    .background(
                        LinearGradient(colors: [Color(white: 0.25), Color(white: 0.08)], startPoint: .top, endPoint: .bottom),
                        in: Circle()
                    )
                    .overlay { Circle().stroke(.white.opacity(0.12), lineWidth: 1) }
            }
            Button(action: player.togglePlayback) {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 30))
                    .frame(width: 82, height: 82)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.89, green: 0.34, blue: 0.16), AppTheme.orange],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        in: Circle()
                    )
                    .overlay { Circle().stroke(.white.opacity(0.22), lineWidth: 1) }
                    .shadow(color: .black.opacity(0.35), radius: 5, y: 3)
            }
            Button(action: player.next) {
                Image(systemName: "forward.fill")
                    .frame(width: 62, height: 62)
                    .background(
                        LinearGradient(colors: [Color(white: 0.25), Color(white: 0.08)], startPoint: .top, endPoint: .bottom),
                        in: Circle()
                    )
                    .overlay { Circle().stroke(.white.opacity(0.12), lineWidth: 1) }
            }
        }
        .font(.title2)
        .buttonStyle(PressableButtonStyle())
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .background(
            LinearGradient(colors: [Color(white: 0.14), Color(white: 0.045)], startPoint: .top, endPoint: .bottom),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.16), radius: 10, y: 6)
    }
}
