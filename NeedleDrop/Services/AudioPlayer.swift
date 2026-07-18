import AVFoundation
import MediaPlayer

@MainActor
final class AudioPlayer: ObservableObject {
    @Published private(set) var currentTrack: Track?
    @Published private(set) var isPlaying = false
    @Published private(set) var elapsed: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0
    @Published var queue: [Track] = []

    private let player = AVPlayer()
    private var timeObserver: Any?
    private weak var library: LibraryStore?

    init() {
        configureAudioSession()
        configureRemoteCommands()
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            Task { @MainActor in
                self?.elapsed = time.seconds.isFinite ? time.seconds : 0
                self?.updateNowPlaying()
            }
        }
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.next() }
        }
    }

    func connect(to library: LibraryStore) {
        self.library = library
    }

    func play(_ track: Track, in tracks: [Track]? = nil) {
        guard let library else { return }
        if let tracks { queue = tracks }
        if queue.isEmpty { queue = [track] }

        currentTrack = track
        duration = track.duration
        elapsed = 0
        player.replaceCurrentItem(with: AVPlayerItem(url: library.audioURL(for: track)))
        player.play()
        isPlaying = true
        updateNowPlaying()
    }

    func togglePlayback() {
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
        updateNowPlaying()
    }

    func seek(to seconds: TimeInterval) {
        player.seek(to: CMTime(seconds: seconds, preferredTimescale: 600))
        elapsed = seconds
    }

    func next() {
        guard let currentTrack,
              let index = queue.firstIndex(where: { $0.id == currentTrack.id }),
              !queue.isEmpty else { return }
        play(queue[(index + 1) % queue.count])
    }

    func previous() {
        if elapsed > 4 {
            seek(to: 0)
            return
        }
        guard let currentTrack,
              let index = queue.firstIndex(where: { $0.id == currentTrack.id }),
              !queue.isEmpty else { return }
        play(queue[(index - 1 + queue.count) % queue.count])
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Playback can still be retried after the system audio session becomes available.
        }
    }

    private func configureRemoteCommands() {
        let commands = MPRemoteCommandCenter.shared()
        commands.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                if self?.isPlaying == false { self?.togglePlayback() }
            }
            return .success
        }
        commands.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                if self?.isPlaying == true { self?.togglePlayback() }
            }
            return .success
        }
        commands.nextTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.next() }
            return .success
        }
        commands.previousTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.previous() }
            return .success
        }
    }

    private func updateNowPlaying() {
        guard let currentTrack else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: currentTrack.title,
            MPMediaItemPropertyArtist: currentTrack.artist,
            MPMediaItemPropertyAlbumTitle: currentTrack.album,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: elapsed,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1 : 0
        ]
    }
}
