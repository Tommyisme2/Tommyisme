import SwiftUI

@main
struct NeedleDropApp: App {
    @StateObject private var library = LibraryStore()
    @StateObject private var player = AudioPlayer()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(library)
                .environmentObject(player)
                .task {
                    player.connect(to: library)
                }
        }
    }
}
