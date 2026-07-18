import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var library: LibraryStore

    private var totalSize: String {
        let bytes = library.tracks.reduce(Int64(0)) { partial, track in
            let values = try? library.audioURL(for: track)
                .resourceValues(forKeys: [.fileSizeKey])
            return partial + Int64(values?.fileSize ?? 0)
        }
        return ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    var body: some View {
        List {
            Section {
                HStack {
                    Label("Songs", systemImage: "music.note")
                    Spacer()
                    Text("\(library.tracks.count)")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Label("Albums", systemImage: "square.stack")
                    Spacer()
                    Text("\(library.albums.count)")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Label("Local storage", systemImage: "internaldrive")
                    Spacer()
                    Text(totalSize)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Library")
            }

            Section("Supported audio") {
                Label("MP3", systemImage: "waveform")
                Label("FLAC", systemImage: "waveform")
            }

            Section {
                Text("NeedleDrop keeps imported audio inside the app and stores your metadata edits in its private library. Deleting the app removes the imported copies.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Text("About")
            }
        }
        .navigationTitle("Settings")
    }
}
