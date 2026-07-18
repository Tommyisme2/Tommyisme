# NeedleDrop

A local-first iPhone music player for MP3 and FLAC albums. NeedleDrop imports audio from Files, reads embedded metadata and artwork, groups songs into albums, and lets you correct metadata inside the app.

## Features

- Multi-file MP3 and FLAC import using the iOS Files picker
- Automatic title, artist, album, genre, year, track, disc, and artwork extraction
- Album and song browsing with search
- Editable album and track metadata plus replacement album artwork
- Local JSON library and private copies of imported audio
- Background playback, lock-screen controls, queue navigation, favorites, and scrubbing
- Record-inspired, tactile SwiftUI interface

## Run

1. Open `NeedleDrop.xcodeproj` in Xcode 16 or newer.
2. Select the `NeedleDrop` target and choose your Apple development team under Signing & Capabilities.
3. Run on an iPhone or iOS 17+ simulator.
4. Open Albums and tap `+` to select one or more `.mp3` or `.flac` files.

Metadata edits affect NeedleDrop's library, not the embedded tags in the original files.
