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
                        SpeakerGrille(rows: 5, columns: 11, dotSize: 6)
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
            Circle()
                .fill(AppTheme.ink)
                .overlay {
                    ForEach(0..<7) { index in
                        Circle()
                            .stroke(.white.opacity(0.10), lineWidth: 1)
                            .padding(CGFloat(index) * 11 + 12)
                    }
                }
                .frame(width: 230, height: 230)
                .offset(x: 58)
                .rotationEffect(.degrees(player.isPlaying ? 360 : 0))
                .animation(
                    player.isPlaying
                        ? .linear(duration: 8).repeatForever(autoreverses: false)
                        : .default,
                    value: player.isPlaying
                )
            ArtworkView(fileName: player.currentTrack?.artworkFileName, cornerRadius: 18)
                .frame(width: 230, height: 230)
                .offset(x: -42)
                .shadow(color: .black.opacity(0.24), radius: 14, y: 9)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 260)
        .padding(.vertical, 10)
        .background(AppTheme.paper, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(AppTheme.ink.opacity(0.08), lineWidth: 1)
        }
    }

    private var metadata: some View {
        VStack(spacing: 6) {
            Text(player.currentTrack?.artist.uppercased() ?? "")
                .font(.caption2.bold())
                .tracking(1.4)
                .foregroundStyle(AppTheme.muted)
            Text(player.currentTrack?.title ?? "Nothing Playing")
                .font(.system(size: 34, weight: .black, design: .rounded))
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
        .background(AppTheme.paper, in: RoundedRectangle(cornerRadius: 16))
    }

    private var controls: some View {
        HStack(spacing: 18) {
            Button(action: player.previous) {
                Image(systemName: "backward.fill")
                    .frame(width: 62, height: 62)
                    .background(.white.opacity(0.10), in: Circle())
            }
            Button(action: player.togglePlayback) {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 30))
                    .frame(width: 82, height: 82)
                    .background(AppTheme.orange, in: Circle())
            }
            Button(action: player.next) {
                Image(systemName: "forward.fill")
                    .frame(width: 62, height: 62)
                    .background(.white.opacity(0.10), in: Circle())
            }
        }
        .font(.title2)
        .buttonStyle(PressableButtonStyle())
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .background(AppTheme.ink, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}
