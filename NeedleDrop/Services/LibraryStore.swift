import AVFoundation
import Combine
import Foundation

@MainActor
final class LibraryStore: ObservableObject {
    @Published private(set) var tracks: [Track] = []
    @Published var isImporting = false
    @Published var importMessage: String?

    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        load()
    }

    var albums: [Album] {
        let grouped = Dictionary(grouping: tracks) {
            "\($0.displayAlbumArtist.lowercased())::\($0.album.lowercased())"
        }

        return grouped.values.map { albumTracks in
            let sorted = albumTracks.sorted {
                ($0.discNumber ?? 1, $0.trackNumber ?? Int.max, $0.title)
                    < ($1.discNumber ?? 1, $1.trackNumber ?? Int.max, $1.title)
            }
            return Album(
                title: sorted.first?.album ?? "Unknown Album",
                artist: sorted.first?.displayAlbumArtist ?? "Unknown Artist",
                tracks: sorted
            )
        }
        .sorted {
            $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
        }
    }

    func audioURL(for track: Track) -> URL {
        audioDirectory.appendingPathComponent(track.fileName)
    }

    func artworkURL(fileName: String?) -> URL? {
        guard let fileName else { return nil }
        let url = artworkDirectory.appendingPathComponent(fileName)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    func importFiles(_ urls: [URL]) async {
        guard !urls.isEmpty else { return }
        isImporting = true
        importMessage = nil

        var imported = 0
        var failed = 0
        for sourceURL in urls {
            do {
                try await importFile(sourceURL)
                imported += 1
            } catch {
                failed += 1
            }
        }

        save()
        isImporting = false
        importMessage = failed == 0
            ? "Imported \(imported) track\(imported == 1 ? "" : "s")."
            : "Imported \(imported); \(failed) could not be read."
    }

    func update(_ editedTrack: Track) {
        guard let index = tracks.firstIndex(where: { $0.id == editedTrack.id }) else { return }
        tracks[index] = editedTrack
        save()
    }

    func updateAlbum(_ album: Album, title: String, artist: String, genre: String, year: Int?) {
        let ids = Set(album.tracks.map(\.id))
        for index in tracks.indices where ids.contains(tracks[index].id) {
            tracks[index].album = title.nonEmpty ?? "Unknown Album"
            tracks[index].albumArtist = artist
            tracks[index].genre = genre
            tracks[index].year = year
        }
        save()
    }

    func setAlbumArtwork(_ data: Data, for album: Album) throws {
        try makeDirectories()
        let fileName = "\(UUID().uuidString).jpg"
        try data.write(to: artworkDirectory.appendingPathComponent(fileName), options: .atomic)
        let ids = Set(album.tracks.map(\.id))
        for index in tracks.indices where ids.contains(tracks[index].id) {
            tracks[index].artworkFileName = fileName
        }
        save()
    }

    func toggleFavorite(_ track: Track) {
        guard let index = tracks.firstIndex(where: { $0.id == track.id }) else { return }
        tracks[index].isFavorite.toggle()
        save()
    }

    func delete(_ tracksToDelete: [Track]) {
        let ids = Set(tracksToDelete.map(\.id))
        for track in tracksToDelete {
            try? fileManager.removeItem(at: audioURL(for: track))
        }
        tracks.removeAll { ids.contains($0.id) }
        save()
    }

    private func importFile(_ sourceURL: URL) async throws {
        let hasAccess = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if hasAccess { sourceURL.stopAccessingSecurityScopedResource() }
        }

        try makeDirectories()
        let ext = sourceURL.pathExtension.lowercased()
        guard ["mp3", "flac"].contains(ext) else { throw ImportError.unsupportedType }

        let destinationName = "\(UUID().uuidString).\(ext)"
        let destination = audioDirectory.appendingPathComponent(destinationName)
        try fileManager.copyItem(at: sourceURL, to: destination)

        do {
            let metadata = try await readMetadata(from: destination)
            tracks.append(Track(
                title: metadata.title.nonEmpty ?? sourceURL.deletingPathExtension().lastPathComponent,
                artist: metadata.artist.nonEmpty ?? "Unknown Artist",
                albumArtist: metadata.albumArtist,
                album: metadata.album.nonEmpty ?? "Unknown Album",
                genre: metadata.genre,
                year: metadata.year,
                trackNumber: metadata.trackNumber,
                discNumber: metadata.discNumber,
                duration: metadata.duration,
                fileName: destinationName,
                artworkFileName: metadata.artworkFileName
            ))
        } catch {
            try? fileManager.removeItem(at: destination)
            throw error
        }
    }

    private func readMetadata(from url: URL) async throws -> ImportedMetadata {
        let asset = AVURLAsset(url: url)
        let metadata = try await asset.load(.metadata)
        let duration = try await asset.load(.duration).seconds

        func string(for identifiers: [AVMetadataIdentifier], keys: [String] = []) async -> String {
            for identifier in identifiers {
                if let item = AVMetadataItem.metadataItems(from: metadata, filteredByIdentifier: identifier).first,
                   let value = try? await item.load(.stringValue) {
                    return value
                }
            }
            for item in metadata {
                let key = item.key.map { String(describing: $0).lowercased() } ?? ""
                if keys.contains(where: key.contains),
                   let value = try? await item.load(.stringValue) {
                    return value
                }
            }
            return ""
        }

        let title = await string(for: [.commonIdentifierTitle])
        let artist = await string(for: [.commonIdentifierArtist])
        let album = await string(for: [.commonIdentifierAlbumName])
        let albumArtist = await string(for: [], keys: ["albumartist", "album artist"])
        let genre = await string(for: [.quickTimeMetadataGenre], keys: ["genre"])
        let yearText = await string(for: [.commonIdentifierCreationDate], keys: ["date", "year"])
        let trackText = await string(for: [], keys: ["tracknumber", "track number"])
        let discText = await string(for: [], keys: ["discnumber", "disc number"])

        var artworkFileName: String?
        if let artworkItem = AVMetadataItem.metadataItems(
            from: metadata,
            filteredByIdentifier: .commonIdentifierArtwork
        ).first,
           let artworkData = try? await artworkItem.load(.dataValue) {
            let name = "\(UUID().uuidString).jpg"
            try artworkData.write(to: artworkDirectory.appendingPathComponent(name), options: .atomic)
            artworkFileName = name
        }

        return ImportedMetadata(
            title: title,
            artist: artist,
            albumArtist: albumArtist,
            album: album,
            genre: genre,
            year: firstInteger(in: yearText),
            trackNumber: firstInteger(in: trackText),
            discNumber: firstInteger(in: discText),
            duration: duration.isFinite ? duration : 0,
            artworkFileName: artworkFileName
        )
    }

    private func firstInteger(in value: String) -> Int? {
        value.split(whereSeparator: { !$0.isNumber }).compactMap { Int($0) }.first
    }

    private var appSupportDirectory: URL {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("NeedleDrop", isDirectory: true)
    }

    private var audioDirectory: URL {
        appSupportDirectory.appendingPathComponent("Audio", isDirectory: true)
    }

    private var artworkDirectory: URL {
        appSupportDirectory.appendingPathComponent("Artwork", isDirectory: true)
    }

    private var libraryURL: URL {
        appSupportDirectory.appendingPathComponent("library.json")
    }

    private func makeDirectories() throws {
        try fileManager.createDirectory(at: audioDirectory, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: artworkDirectory, withIntermediateDirectories: true)
    }

    private func load() {
        guard let data = try? Data(contentsOf: libraryURL),
              let decoded = try? decoder.decode([Track].self, from: data) else { return }
        tracks = decoded
    }

    private func save() {
        do {
            try makeDirectories()
            try encoder.encode(tracks).write(to: libraryURL, options: .atomic)
        } catch {
            importMessage = "The library could not be saved."
        }
    }
}

private struct ImportedMetadata {
    let title: String
    let artist: String
    let albumArtist: String
    let album: String
    let genre: String
    let year: Int?
    let trackNumber: Int?
    let discNumber: Int?
    let duration: TimeInterval
    let artworkFileName: String?
}

private enum ImportError: Error {
    case unsupportedType
}

private extension String {
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
