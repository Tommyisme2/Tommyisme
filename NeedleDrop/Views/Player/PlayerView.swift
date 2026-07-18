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
                Color(red: 0.91, green: 0.90, blue: 0.87)
                    .ignoresSafeArea()

                VStack(spacing: 28) {
                    Spacer()
                    record
                    metadata
                    progress
                    controls
                    Spacer()
                }
                .padding(.horizontal, 30)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: dismiss.callAsFunction) {
                        Image(systemName: "chevron.down")
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("NOW PLAYING")
                        .font(.caption2.weight(.semibold))
                        .tracking(1.4)
                        .foregroundStyle(.secondary)
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
            .onChange(of: player.elapsed) { _, value in
                if !isScrubbing { scrubValue = value }
            }
        }
    }

    private var record: some View {
        ZStack {
            Circle()
                .fill(.black)
                .overlay {
                    ForEach(0..<8) { index in
                        Circle()
                            .stroke(.white.opacity(0.08), lineWidth: 1)
                            .padding(CGFloat(index) * 13 + 12)
                    }
                }
                .rotationEffect(.degrees(player.isPlaying ? 360 : 0))
                .animation(
                    player.isPlaying
                        ? .linear(duration: 8).repeatForever(autoreverses: false)
                        : .default,
                    value: player.isPlaying
                )
            ArtworkView(fileName: player.currentTrack?.artworkFileName, cornerRadius: 999)
                .padding(78)
            Circle()
                .fill(Color(red: 0.91, green: 0.90, blue: 0.87))
                .frame(width: 16, height: 16)
        }
        .frame(maxWidth: 340)
        .aspectRatio(1, contentMode: .fit)
        .shadow(color: .black.opacity(0.22), radius: 22, y: 14)
    }

    private var metadata: some View {
        VStack(spacing: 7) {
            Text(player.currentTrack?.title ?? "Nothing Playing")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text(player.currentTrack?.artist ?? "")
                .font(.body)
                .foregroundStyle(.secondary)
            Text(player.currentTrack?.album ?? "")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
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
            .tint(.orange)
            HStack {
                Text(scrubValue.clockString)
                Spacer()
                Text(player.duration.clockString)
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
        }
    }

    private var controls: some View {
        HStack(spacing: 44) {
            Button(action: player.previous) {
                Image(systemName: "backward.fill")
            }
            Button(action: player.togglePlayback) {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 32))
                    .frame(width: 74, height: 74)
                    .background(.black, in: Circle())
                    .foregroundStyle(.white)
            }
            Button(action: player.next) {
                Image(systemName: "forward.fill")
            }
        }
        .font(.title2)
        .buttonStyle(PressableButtonStyle())
    }
}
