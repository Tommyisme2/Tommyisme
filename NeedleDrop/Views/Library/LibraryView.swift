import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var library: LibraryStore
    @Binding var isShowingImporter: Bool
    @State private var searchText = ""
    @State private var featuredAlbumID: String?

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    private var filteredAlbums: [Album] {
        guard !searchText.isEmpty else { return library.albums }
        return library.albums.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
                || $0.artist.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var featuredAlbum: Album? {
        filteredAlbums.first(where: { $0.id == featuredAlbumID }) ?? filteredAlbums.first
    }

    var body: some View {
        Group {
            if library.albums.isEmpty {
                emptyLibrary
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        listeningCard

                        HStack(alignment: .firstTextBaseline) {
                            Text("Albums")
                                .font(.system(size: 32, weight: .black, design: .rounded))
                            Spacer()
                            Text("\(filteredAlbums.count) RELEASES")
                                .font(.caption2.bold())
                                .tracking(1.1)
                                .foregroundStyle(AppTheme.muted)
                        }

                        LazyVGrid(columns: columns, alignment: .leading, spacing: 24) {
                            ForEach(filteredAlbums) { album in
                                NavigationLink(value: album) {
                                    AlbumTile(album: album)
                                }
                                .buttonStyle(PressableButtonStyle())
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 10)
                    .padding(.bottom, 28)
                }
            }
        }
        .background(AppTheme.canvas.ignoresSafeArea())
        .navigationTitle("Music")
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
                        Image(systemName: "plus")
                            .fontWeight(.bold)
                    }
                }
                .disabled(library.isImporting)
            }
        }
        .tint(AppTheme.ink)
    }

    private var emptyLibrary: some View {
        VStack(spacing: 24) {
            SpeakerGrille(rows: 8, columns: 8, dotSize: 8)
            VStack(spacing: 8) {
                Text("YOUR MUSIC,\nYOUR WAY.")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .multilineTextAlignment(.center)
                Text("Bring in MP3 and FLAC albums.\nWe’ll sort the rest.")
                    .foregroundStyle(AppTheme.muted)
                    .multilineTextAlignment(.center)
            }
            Button {
                isShowingImporter = true
            } label: {
                Label("IMPORT MUSIC", systemImage: "plus")
                    .font(.subheadline.bold())
                    .tracking(0.8)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 14)
                    .background(AppTheme.ink, in: Capsule())
                    .foregroundStyle(AppTheme.paper)
            }
            .buttonStyle(PressableButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(30)
    }

    private var listeningCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Listening to...")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                Spacer()
                Button {
                    guard !filteredAlbums.isEmpty else { return }
                    let current = filteredAlbums.firstIndex { $0.id == featuredAlbum?.id } ?? 0
                    featuredAlbumID = filteredAlbums[(current + 1) % filteredAlbums.count].id
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                        .font(.caption.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(AppTheme.ink.opacity(0.06), in: Capsule())
                }
                .buttonStyle(PressableButtonStyle())
            }

            ZStack(alignment: .bottomTrailing) {
                AlbumStack(
                    albums: Array(filteredAlbums.prefix(6)),
                    selectedID: featuredAlbum?.id,
                    select: { featuredAlbumID = $0.id }
                )
                if let album = featuredAlbum {
                    NavigationLink(value: album) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(album.artist)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(album.title)
                                .font(.headline)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 13))
                        .overlay {
                            RoundedRectangle(cornerRadius: 13)
                                .stroke(.white.opacity(0.7), lineWidth: 1)
                        }
                    }
                    .buttonStyle(PressableButtonStyle())
                    .foregroundStyle(AppTheme.ink)
                }
            }
        }
        .padding(18)
        .background(AppTheme.paper, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(AppTheme.ink.opacity(0.08), lineWidth: 1)
        }
    }
}

private struct AlbumStack: View {
    let albums: [Album]
    let selectedID: String?
    let select: (Album) -> Void

    var body: some View {
        GeometryReader { proxy in
            let coverSize = min(170, proxy.size.width * 0.48)
            ZStack(alignment: .leading) {
                ForEach(Array(albums.enumerated()), id: \.element.id) { index, album in
                    Button { select(album) } label: {
                        ArtworkView(fileName: album.artworkFileName, cornerRadius: 14)
                            .frame(width: coverSize, height: coverSize)
                            .overlay {
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(.black.opacity(0.16), lineWidth: 1)
                            }
                            .shadow(color: .black.opacity(0.18), radius: 8, y: 5)
                    }
                    .buttonStyle(PressableButtonStyle())
                    .offset(x: CGFloat(index) * min(42, (proxy.size.width - coverSize) / CGFloat(max(albums.count - 1, 1))))
                    .scaleEffect(album.id == selectedID ? 1.03 : 0.96)
                    .zIndex(album.id == selectedID ? 20 : Double(index))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .frame(height: 190)
    }
}

private struct AlbumTile: View {
    let album: Album

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            ArtworkView(fileName: album.artworkFileName, cornerRadius: 14)
                .aspectRatio(1, contentMode: .fit)
                .shadow(color: .black.opacity(0.14), radius: 8, y: 5)
            Text(album.title)
                .font(.system(.headline, design: .rounded, weight: .bold))
                .lineLimit(1)
            Text(album.artist)
                .font(.caption)
                .foregroundStyle(AppTheme.muted)
                .lineLimit(1)
        }
        .foregroundStyle(AppTheme.ink)
    }
}
