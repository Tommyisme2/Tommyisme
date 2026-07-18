import SwiftUI

enum AppTheme {
    static let canvas = Color(red: 0.93, green: 0.92, blue: 0.88)
    static let paper = Color(red: 0.98, green: 0.98, blue: 0.96)
    static let ink = Color(red: 0.04, green: 0.04, blue: 0.04)
    static let muted = Color(red: 0.57, green: 0.56, blue: 0.52)
    static let orange = Color(red: 1.0, green: 0.31, blue: 0.18)
    static let green = Color(red: 0.10, green: 0.48, blue: 0.23)
    static let yellow = Color(red: 1.0, green: 0.82, blue: 0.0)
}

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
                    AppTheme.paper
                    Circle()
                        .fill(AppTheme.ink)
                        .padding(22)
                    Circle()
                        .fill(AppTheme.orange)
                        .frame(width: 22, height: 22)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

struct SpeakerGrille: View {
    var rows = 9
    var columns = 9
    var dotSize: CGFloat = 7

    var body: some View {
        VStack(spacing: dotSize * 0.85) {
            ForEach(0..<rows, id: \.self) { _ in
                HStack(spacing: dotSize * 0.85) {
                    ForEach(0..<columns, id: \.self) { _ in
                        Circle()
                            .fill(AppTheme.ink)
                            .frame(width: dotSize, height: dotSize)
                    }
                }
            }
        }
        .accessibilityHidden(true)
    }
}

struct EditorialIconButton: View {
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .bold))
                .frame(width: 42, height: 42)
                .background(AppTheme.paper, in: Circle())
                .overlay { Circle().stroke(AppTheme.ink.opacity(0.08), lineWidth: 1) }
        }
        .buttonStyle(PressableButtonStyle())
        .foregroundStyle(AppTheme.ink)
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
