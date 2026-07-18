import SwiftUI

struct SongsView: View {
    @EnvironmentObject private var library: LibraryStore
    @EnvironmentObject private var player: AudioPlayer
    @State private var searchText = ""
    @State private var editingTrack: Track?

    private var filteredTracks: [Track] {
        let sorted = library.tracks.sorted {
            $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
        }
        guard !searchText.isEmpty else { return sorted }
        return sorted.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
                || $0.artist.localizedCaseInsensitiveContains(searchText)
                || $0.album.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        List {
            ForEach(filteredTracks) { track in
                Button {
                    player.play(track, in: filteredTracks)
                } label: {
                    HStack(spacing: 12) {
                        ArtworkView(fileName: track.artworkFileName, cornerRadius: 9)
                            .frame(width: 50, height: 50)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(track.title)
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            Text("\(track.artist) · \(track.album)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        Menu {
                            Button {
                                library.toggleFavorite(track)
                            } label: {
                                Label(
                                    track.isFavorite ? "Remove Favorite" : "Favorite",
                                    systemImage: track.isFavorite ? "heart.slash" : "heart"
                                )
                            }
                            Button("Edit Metadata", systemImage: "pencil") {
                                editingTrack = track
                            }
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                library.delete([track])
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .frame(width: 32, height: 40)
                        }
                    }
                }
            }
        }
        .overlay {
            if library.tracks.isEmpty {
                ContentUnavailableView(
                    "No songs yet",
                    systemImage: "music.note",
                    description: Text("Import an album from the Albums tab.")
                )
            }
        }
        .navigationTitle("Songs")
        .searchable(text: $searchText, prompt: "Songs, artists, albums")
        .sheet(item: $editingTrack) { track in
            TrackEditorView(track: track)
        }
    }
}

private struct TrackEditorView: View {
    @EnvironmentObject private var library: LibraryStore
    @Environment(\.dismiss) private var dismiss
    @State private var draft: Track
    @State private var year: String
    @State private var trackNumber: String
    @State private var discNumber: String

    init(track: Track) {
        _draft = State(initialValue: track)
        _year = State(initialValue: track.year.map(String.init) ?? "")
        _trackNumber = State(initialValue: track.trackNumber.map(String.init) ?? "")
        _discNumber = State(initialValue: track.discNumber.map(String.init) ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Track metadata") {
                    TextField("Title", text: $draft.title)
                    TextField("Artist", text: $draft.artist)
                    TextField("Album", text: $draft.album)
                    TextField("Album artist", text: $draft.albumArtist)
                    TextField("Genre", text: $draft.genre)
                    TextField("Year", text: $year).keyboardType(.numberPad)
                    TextField("Track number", text: $trackNumber).keyboardType(.numberPad)
                    TextField("Disc number", text: $discNumber).keyboardType(.numberPad)
                }
            }
            .navigationTitle("Edit Song")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        draft.year = Int(year)
                        draft.trackNumber = Int(trackNumber)
                        draft.discNumber = Int(discNumber)
                        library.update(draft)
                        dismiss()
                    }
                    .disabled(draft.title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
