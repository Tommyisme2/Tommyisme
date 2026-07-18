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
                        VStack(spacing: 18) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.ink)
                                    .frame(width: 190, height: 190)
                                    .offset(x: 58)
                                    .overlay {
                                        Circle()
                                            .stroke(.white.opacity(0.1), lineWidth: 1)
                                            .frame(width: 152, height: 152)
                                            .offset(x: 58)
                                    }
                                ArtworkView(fileName: album.artworkFileName, cornerRadius: 16)
                                    .frame(width: 190, height: 190)
                                    .offset(x: -42)
                                    .shadow(color: .black.opacity(0.18), radius: 12, y: 8)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 210)

                            VStack(spacing: 5) {
                                Text(album.artist.uppercased())
                                    .font(.caption2.bold())
                                    .tracking(1.3)
                                    .foregroundStyle(AppTheme.muted)
                                Text(album.title)
                                    .font(.system(size: 30, weight: .black, design: .rounded))
                                    .multilineTextAlignment(.center)
                                Text("\(album.year.map(String.init) ?? "LOCAL") · \(album.tracks.count) TRACKS · \(album.duration.clockString)")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.muted)
                            }
                            Button {
                                if let first = album.tracks.first {
                                    player.play(first, in: album.tracks)
                                }
                            } label: {
                                Label("PLAY ALBUM", systemImage: "play.fill")
                                    .font(.subheadline.bold())
                                    .tracking(0.6)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                            }
                            .buttonStyle(.borderedProminent)
                            .buttonBorderShape(.capsule)
                            .tint(AppTheme.ink)
                        }
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .listRowBackground(AppTheme.paper)
                    }

                    Section("Tracks") {
                        ForEach(album.tracks) { track in
                            Button {
                                player.play(track, in: album.tracks)
                            } label: {
                                HStack(spacing: 12) {
                                    Text(track.trackNumber.map(String.init) ?? "–")
                                        .font(.caption.bold().monospacedDigit())
                                        .foregroundStyle(.white)
                                        .frame(width: 30, height: 30)
                                        .background(AppTheme.ink, in: Circle())
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(track.title)
                                            .fontWeight(.semibold)
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
                        .listRowBackground(AppTheme.paper)
                        .onDelete { offsets in
                            library.delete(offsets.map { album.tracks[$0] })
                            if library.albums.first(where: { $0.id == albumID }) == nil {
                                dismiss()
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(AppTheme.canvas)
                .navigationTitle(album.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    Button("Edit") { isEditing = true }
                }
                .tint(AppTheme.ink)
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
