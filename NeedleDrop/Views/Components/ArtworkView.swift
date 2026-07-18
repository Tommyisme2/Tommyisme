import SwiftUI

enum AppTheme {
    static let canvas = Color(red: 0.945, green: 0.94, blue: 0.925)
    static let paper = Color(red: 0.985, green: 0.982, blue: 0.972)
    static let raised = Color(red: 0.90, green: 0.895, blue: 0.875)
    static let ink = Color(red: 0.075, green: 0.073, blue: 0.068)
    static let muted = Color(red: 0.43, green: 0.42, blue: 0.39)
    static let orange = Color(red: 0.76, green: 0.25, blue: 0.10)
    static let panelStroke = Color.black.opacity(0.09)
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
                    LinearGradient(
                        colors: [Color(red: 0.76, green: 0.79, blue: 0.78),
                                 Color(red: 0.38, green: 0.43, blue: 0.45)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Circle()
                        .fill(
                            AngularGradient(
                                colors: [.black, Color(white: 0.18), .black, Color(white: 0.12), .black],
                                center: .center
                            )
                        )
                        .padding(22)
                    Circle()
                        .fill(Color(red: 0.82, green: 0.76, blue: 0.63))
                        .frame(width: 34, height: 34)
                    Circle()
                        .fill(AppTheme.ink)
                        .frame(width: 6, height: 6)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

struct VinylRecordView: View {
    var artworkFileName: String?

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    AngularGradient(
                        colors: [
                            Color(white: 0.025),
                            Color(white: 0.15),
                            Color(white: 0.035),
                            Color(white: 0.11),
                            Color(white: 0.025)
                        ],
                        center: .center
                    )
                )
            ForEach(0..<11, id: \.self) { index in
                Circle()
                    .stroke(.white.opacity(index.isMultiple(of: 3) ? 0.10 : 0.045), lineWidth: 0.7)
                    .padding(CGFloat(index) * 7 + 7)
            }
            ArtworkView(fileName: artworkFileName, cornerRadius: 999)
                .padding(72)
            Circle()
                .fill(Color(white: 0.08))
                .frame(width: 7, height: 7)
            LinearGradient(
                colors: [.white.opacity(0.18), .clear, .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(Circle())
        }
        .aspectRatio(1, contentMode: .fit)
        .shadow(color: .black.opacity(0.24), radius: 12, y: 7)
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
                            .fill(
                                RadialGradient(
                                    colors: [Color(white: 0.03), Color(white: 0.22)],
                                    center: .topLeading,
                                    startRadius: 0,
                                    endRadius: dotSize
                                )
                            )
                            .frame(width: dotSize, height: dotSize)
                            .shadow(color: .white.opacity(0.45), radius: 0.4, x: -0.4, y: -0.4)
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
                .background(
                    LinearGradient(colors: [AppTheme.paper, AppTheme.raised], startPoint: .top, endPoint: .bottom),
                    in: Circle()
                )
                .overlay { Circle().stroke(AppTheme.panelStroke, lineWidth: 1) }
                .shadow(color: .black.opacity(0.10), radius: 3, y: 2)
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
