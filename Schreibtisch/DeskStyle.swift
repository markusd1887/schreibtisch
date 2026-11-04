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

// MARK: - Papier-Karte

/// Wie eine Karte oben verziert ist.
enum DeskDecoration {
    /// Eine rote Pinnnadel
    case pin
    /// Ein Streifen Klebeband
    case tape
    /// Die Metallklemme eines Klemmbretts
    case clip
}

/// Ein Rahmen, der beliebigen Inhalt wie ein Stück Papier auf dem Schreibtisch aussehen lässt.
///
/// `Content` ist ein Platzhalter für "irgendeine Ansicht" – so kann dieselbe
/// Karte To-Dos, Notizen oder Supplements enthalten.
struct DeskCard<Content: View>: View {
    let paper: Color
    let decoration: DeskDecoration
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(.top, 10) // Platz für die Deko oben
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                if decoration == .clip {
                    // Das Klemmbrett: eine Holzplatte, auf der das Papier liegt
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(red: 0.36, green: 0.22, blue: 0.12))
                        .padding(-10)
                        .shadow(color: .black.opacity(0.35), radius: 8, y: 5)
                }
                RoundedRectangle(cornerRadius: 4)
                    .fill(paper.gradient) // `.gradient` gibt der Farbe einen ganz leichten Verlauf
                    .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 4)
            }
            .overlay(alignment: .top) {
                DecorationView(decoration: decoration)
            }
            // Papier bleibt immer hell – auch wenn der Mac im Dunkelmodus ist.
            .environment(\.colorScheme, .light)
    }
}

/// Zeichnet die Deko (Nadel, Klebeband oder Klemme) oben auf eine Karte.
private struct DecorationView: View {
    let decoration: DeskDecoration

    var body: some View {
        switch decoration {
        case .pin:
            Circle()
                .fill(
                    RadialGradient(colors: [Color(red: 1, green: 0.45, blue: 0.4), .red,
                                            Color(red: 0.55, green: 0, blue: 0)],
                                   center: UnitPoint(x: 0.35, y: 0.3),
                                   startRadius: 1, endRadius: 12)
                )
                .frame(width: 20, height: 20)
                .shadow(color: .black.opacity(0.4), radius: 2, x: 2, y: 3)
                .offset(y: -8)

        case .tape:
            Rectangle()
                .fill(Color(red: 0.95, green: 0.92, blue: 0.82).opacity(0.75))
                .frame(width: 110, height: 26)
                .shadow(color: .black.opacity(0.15), radius: 1, y: 1)
                .rotationEffect(.degrees(-3))
                .offset(y: -13)

        case .clip:
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(colors: [Color(white: 0.9), Color(white: 0.6), Color(white: 0.8)],
                                   startPoint: .top, endPoint: .bottom)
                )
                .frame(width: 120, height: 26)
                .overlay {
                    // Das Loch in der Klemme
                    Capsule()
                        .fill(Color(white: 0.35))
                        .frame(width: 30, height: 8)
                }
                .shadow(color: .black.opacity(0.4), radius: 3, y: 2)
                .offset(y: -18)
        }
    }
}

// MARK: - Papierfarben

extension Color {
    /// Leicht cremiges Notizblock-Weiß
    static let notepadPaper = Color(red: 0.99, green: 0.98, blue: 0.94)
    /// Gelb wie ein Klebezettel
    static let stickyNoteYellow = Color(red: 1.0, green: 0.93, blue: 0.55)
    /// Weißes Blatt auf dem Klemmbrett
    static let clipboardPaper = Color(red: 0.97, green: 0.97, blue: 0.97)
}

#Preview {
    ZStack {
        DeskBackground()
        DeskCard(paper: .stickyNoteYellow, decoration: .tape) {
            Text("Hallo Schreibtisch").padding()
        }
        .frame(width: 300, height: 200)
    }
    .frame(width: 600, height: 400)
}
