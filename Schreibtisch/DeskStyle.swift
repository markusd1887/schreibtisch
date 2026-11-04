import SwiftUI

// MARK: - Holz-Hintergrund

/// Die Schreibtischplatte: ein Holz-Farbverlauf mit gezeichneter Maserung.
///
/// Wir brauchen dafür kein Bild. Die Maserung wird mit `Canvas` gezeichnet –
/// einer Zeichenfläche, auf der man Linien und Formen selbst malen kann.
struct DeskBackground: View {
    var body: some View {
        ZStack {
            // Grundfarbe: dunkler Nussbaum, oben etwas heller als unten
            LinearGradient(
                colors: [.walnutLight, .walnut, .walnutDark],
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

// MARK: - Schreibunterlage aus Leder

/// Die Lederunterlage, auf der der Papierblock liegt:
/// rotbraunes Leder mit Messing-Rand und einer gestrichelten Ziernaht.
struct LeatherPad: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(LinearGradient(colors: [.leather, .leatherDark],
                                 startPoint: .top, endPoint: .bottom))
            // Ziernaht: eine gestrichelte Linie knapp innerhalb des Rands
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.brass.opacity(0.55),
                                  style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                    .padding(6)
            }
            // Messing-Rand außen
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.brass, lineWidth: 2)
            }
            .shadow(color: .black.opacity(0.45), radius: 12, y: 6)
    }
}

// MARK: - Tischkante

/// Die hintere Tischkante: Hier stößt der Tisch an die Wand.
/// Ein dunkler Streifen, der nach vorn ausläuft, erzeugt die Tiefe.
struct DeskEdge: View {
    var body: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Color.walnutDark).frame(height: 3)
            LinearGradient(colors: [.black.opacity(0.35), .clear], startPoint: .top, endPoint: .bottom)
                .frame(height: 14)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Farbpalette

/// Alle Farben des Schreibtischs an einer Stelle.
///
/// Eine "Farbpalette" heißt: Die Ansichten benutzen nur diese Namen
/// (z. B. `.leather`) statt fester Zahlenwerte. Will man einen Farbton ändern,
/// passiert das nur hier – und überall ändert er sich mit.
extension Color {
    // Holz (Nussbaum)
    static let walnutLight = Color(red: 0.38, green: 0.25, blue: 0.17)
    static let walnut      = Color(red: 0.30, green: 0.19, blue: 0.13)
    static let walnutDark  = Color(red: 0.21, green: 0.13, blue: 0.09)

    // Leder und Messing
    static let leather     = Color(red: 0.45, green: 0.19, blue: 0.14)
    static let leatherDark = Color(red: 0.33, green: 0.13, blue: 0.10)
    static let brass       = Color(red: 0.72, green: 0.58, blue: 0.35)
    static let brassDark   = Color(red: 0.50, green: 0.38, blue: 0.20)

    /// Bordeaux für Akzente (Kalender-Kopf, heutiger Tag)
    static let bordeaux    = Color(red: 0.50, green: 0.13, blue: 0.16)

    // Wand (warmer Putz) und Fensterrahmen
    static let wallLight   = Color(red: 0.91, green: 0.86, blue: 0.78)
    static let wall        = Color(red: 0.83, green: 0.77, blue: 0.67)
    static let windowFrame = Color(red: 0.96, green: 0.93, blue: 0.86)

    /// Warmes Elfenbein für alles Papier
    static let notepadPaper = Color(red: 0.97, green: 0.94, blue: 0.86)

    /// Gedämpfte Klebezettel-Farben: Honig, Altrosa, Salbei, Taubenblau
    static let stickyNoteColors: [Color] = [
        Color(red: 0.95, green: 0.85, blue: 0.56),
        Color(red: 0.92, green: 0.77, blue: 0.75),
        Color(red: 0.79, green: 0.86, blue: 0.73),
        Color(red: 0.77, green: 0.83, blue: 0.89)
    ]
}

#Preview {
    DeskBackground()
        .frame(width: 600, height: 400)
}
