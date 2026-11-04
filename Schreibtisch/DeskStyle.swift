import SwiftUI

// MARK: - Holz-Hintergrund

/// Die Schreibtischplatte: ein Holz-Farbverlauf mit gezeichneter Maserung.
///
/// Wir brauchen dafür kein Bild. Die Maserung wird mit `Canvas` gezeichnet –
/// einer Zeichenfläche, auf der man Linien und Formen selbst malen kann.
struct DeskBackground: View {
    var body: some View {
        ZStack {
            // Grundfarbe: warmes Holz, oben etwas heller als unten
            LinearGradient(
                colors: [
                    Color(red: 0.62, green: 0.42, blue: 0.26),
                    Color(red: 0.52, green: 0.33, blue: 0.19),
                    Color(red: 0.44, green: 0.27, blue: 0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Maserung: viele leicht gewellte, halb durchsichtige Linien
            Canvas { context, size in
                let lineCount = 70
                for i in 0..<lineCount {
                    let baseY = size.height * CGFloat(i) / CGFloat(lineCount)
                    // Feste "Zufallswerte" aus der Zeilennummer, damit sich
                    // das Muster beim Neuzeichnen nicht verändert.
                    let wave = 2 + CGFloat((i * 37) % 7)
                    let phase = CGFloat((i * 53) % 11)
                    let opacity = 0.04 + Double((i * 29) % 5) * 0.02

                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: baseY))
                    var x: CGFloat = 0
                    while x <= size.width {
                        let y = baseY + sin(x / 90 + phase) * wave
                        path.addLine(to: CGPoint(x: x, y: y))
                        x += 8
                    }
                    let color = i.isMultiple(of: 3) ? Color.white : Color.black
                    context.stroke(path,
                                   with: .color(color.opacity(opacity)),
                                   lineWidth: i.isMultiple(of: 4) ? 2 : 1)
                }
            }

            // Leichte Abdunklung an den Rändern ("Vignette"), wirkt räumlicher
            RadialGradient(
                colors: [.clear, .black.opacity(0.25)],
                center: .center,
                startRadius: 300,
                endRadius: 1100
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - Papierfarben

extension Color {
    /// Leicht cremiges Notizblock-Weiß
    static let notepadPaper = Color(red: 0.99, green: 0.98, blue: 0.94)
}

#Preview {
    DeskBackground()
        .frame(width: 600, height: 400)
}
