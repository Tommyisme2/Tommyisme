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
                HStack(spacing: 10) {
                    LibraryStat(value: "\(library.tracks.count)", label: "SONGS")
                    LibraryStat(value: "\(library.albums.count)", label: "ALBUMS")
                    LibraryStat(value: totalSize, label: "STORAGE")
                }
                .padding(.vertical, 8)
                .listRowBackground(AppTheme.paper)
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
        .scrollContentBackground(.hidden)
        .background(AppTheme.canvas)
        .tint(AppTheme.ink)
    }
}

private struct LibraryStat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 5) {
            Text(value)
                .font(.system(.headline, design: .rounded, weight: .black))
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(AppTheme.muted)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 78)
        .background(AppTheme.canvas, in: RoundedRectangle(cornerRadius: 16))
    }
}
