import SwiftUI

struct ArtworkView: View {
    let fileName: String?
    var cornerRadius: CGFloat = 18

    @EnvironmentObject private var library: LibraryStore

    var body: some View {
        Group {
            if let url = library.artworkURL(fileName: fileName),
               let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [Color(red: 0.84, green: 0.86, blue: 0.82),
                                 Color(red: 0.56, green: 0.63, blue: 0.66)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Circle()
                        .fill(.black.opacity(0.84))
                        .padding(22)
                    Circle()
                        .fill(.white.opacity(0.84))
                        .frame(width: 22, height: 22)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .opacity(configuration.isPressed ? 0.72 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

extension TimeInterval {
    var clockString: String {
        guard isFinite && self >= 0 else { return "0:00" }
        let value = Int(self)
        return String(format: "%d:%02d", value / 60, value % 60)
    }
}
