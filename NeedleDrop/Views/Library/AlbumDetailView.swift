import PhotosUI
import SwiftUI

struct AlbumDetailView: View {
    let albumID: String

    @EnvironmentObject private var library: LibraryStore
    @EnvironmentObject private var player: AudioPlayer
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false

    private var album: Album? {
        library.albums.first { $0.id == albumID }
    }

    var body: some View {
        Group {
            if let album {
                List {
                    Section {
                        VStack(spacing: 14) {
                            ArtworkView(fileName: album.artworkFileName)
                                .frame(maxWidth: 260)
                                .aspectRatio(1, contentMode: .fit)
                                .shadow(color: .black.opacity(0.17), radius: 16, y: 9)
                            VStack(spacing: 4) {
                                Text(album.title)
                                    .font(.title2.bold())
                                Text(album.artist)
                                    .foregroundStyle(.secondary)
                                Text(album.year.map(String.init) ?? "\(album.tracks.count) tracks")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            Button {
                                if let first = album.tracks.first {
                                    player.play(first, in: album.tracks)
                                }
                            } label: {
                                Label("Play album", systemImage: "play.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)
                        }
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                    }

                    Section("Tracks") {
                        ForEach(album.tracks) { track in
                            Button {
                                player.play(track, in: album.tracks)
                            } label: {
                                HStack(spacing: 12) {
                                    Text(track.trackNumber.map(String.init) ?? "–")
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                        .frame(width: 24)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(track.title)
                                            .foregroundStyle(.primary)
                                        Text(track.artist)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text(track.duration.clockString)
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                        .onDelete { offsets in
                            library.delete(offsets.map { album.tracks[$0] })
                            if library.albums.first(where: { $0.id == albumID }) == nil {
                                dismiss()
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .navigationTitle(album.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    Button("Edit") { isEditing = true }
                }
                .sheet(isPresented: $isEditing) {
                    AlbumEditorView(album: album)
                }
            } else {
                ContentUnavailableView("Album not found", systemImage: "opticaldisc")
            }
        }
    }
}

private struct AlbumEditorView: View {
    let album: Album

    @EnvironmentObject private var library: LibraryStore
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var artist: String
    @State private var genre: String
    @State private var year: String
    @State private var selectedPhoto: PhotosPickerItem?

    init(album: Album) {
        self.album = album
        _title = State(initialValue: album.title)
        _artist = State(initialValue: album.artist)
        _genre = State(initialValue: album.tracks.first?.genre ?? "")
        _year = State(initialValue: album.year.map(String.init) ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        ArtworkView(fileName: album.artworkFileName)
                            .frame(width: 150, height: 150)
                        Spacer()
                    }
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label("Choose album artwork", systemImage: "photo")
                    }
                }

                Section("Album metadata") {
                    TextField("Album title", text: $title)
                    TextField("Album artist", text: $artist)
                    TextField("Genre", text: $genre)
                    TextField("Year", text: $year)
                        .keyboardType(.numberPad)
                }

                Section {
                    Text("Edits are stored in this library. Your original imported file tags are not rewritten.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Edit Album")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        library.updateAlbum(
                            album,
                            title: title,
                            artist: artist,
                            genre: genre,
                            year: Int(year)
                        )
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onChange(of: selectedPhoto) { _, item in
                Task {
                    guard let data = try? await item?.loadTransferable(type: Data.self) else { return }
                    try? library.setAlbumArtwork(data, for: album)
                }
            }
        }
    }
}
