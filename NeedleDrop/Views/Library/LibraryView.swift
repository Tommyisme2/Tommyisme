import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var library: LibraryStore
    @Binding var isShowingImporter: Bool
    @State private var searchText = ""

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    private var filteredAlbums: [Album] {
        guard !searchText.isEmpty else { return library.albums }
        return library.albums.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
                || $0.artist.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        Group {
            if library.albums.isEmpty {
                ContentUnavailableView {
                    Label("Your records belong here", systemImage: "opticaldisc")
                } description: {
                    Text("Import MP3 or FLAC files. Tags are read automatically and grouped into albums.")
                } actions: {
                    Button("Import music") { isShowingImporter = true }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                }
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, alignment: .leading, spacing: 22) {
                        ForEach(filteredAlbums) { album in
                            NavigationLink(value: album) {
                                AlbumTile(album: album)
                            }
                            .buttonStyle(PressableButtonStyle())
                        }
                    }
                    .padding()
                }
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Your Library")
        .navigationDestination(for: Album.self) { AlbumDetailView(albumID: $0.id) }
        .searchable(text: $searchText, prompt: "Albums and artists")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isShowingImporter = true
                } label: {
                    if library.isImporting {
                        ProgressView()
                    } else {
                        Label("Import", systemImage: "plus")
                    }
                }
                .disabled(library.isImporting)
            }
        }
    }
}

private struct AlbumTile: View {
    let album: Album

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            ArtworkView(fileName: album.artworkFileName)
                .aspectRatio(1, contentMode: .fit)
                .shadow(color: .black.opacity(0.13), radius: 10, y: 6)
            Text(album.title)
                .font(.headline)
                .lineLimit(1)
            Text(album.artist)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .foregroundStyle(.primary)
    }
}
