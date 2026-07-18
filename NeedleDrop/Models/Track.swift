import Foundation

struct Track: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var artist: String
    var albumArtist: String
    var album: String
    var genre: String
    var year: Int?
    var trackNumber: Int?
    var discNumber: Int?
    var duration: TimeInterval
    var fileName: String
    var artworkFileName: String?
    var dateAdded: Date
    var isFavorite: Bool

    init(
        id: UUID = UUID(),
        title: String,
        artist: String = "Unknown Artist",
        albumArtist: String = "",
        album: String = "Unknown Album",
        genre: String = "",
        year: Int? = nil,
        trackNumber: Int? = nil,
        discNumber: Int? = nil,
        duration: TimeInterval = 0,
        fileName: String,
        artworkFileName: String? = nil,
        dateAdded: Date = .now,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.albumArtist = albumArtist
        self.album = album
        self.genre = genre
        self.year = year
        self.trackNumber = trackNumber
        self.discNumber = discNumber
        self.duration = duration
        self.fileName = fileName
        self.artworkFileName = artworkFileName
        self.dateAdded = dateAdded
        self.isFavorite = isFavorite
    }

    var displayAlbumArtist: String {
        albumArtist.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? artist : albumArtist
    }
}

struct Album: Identifiable, Hashable {
    let title: String
    let artist: String
    let tracks: [Track]

    var id: String { "\(artist.lowercased())::\(title.lowercased())" }
    var artworkFileName: String? { tracks.compactMap(\.artworkFileName).first }
    var year: Int? { tracks.compactMap(\.year).min() }
    var duration: TimeInterval { tracks.reduce(0) { $0 + $1.duration } }
}
