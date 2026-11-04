import SwiftUI
import SwiftData

/// Die Wand hinter dem Schreibtisch.
///
/// Hier hängen Dinge, die man aus dem Augenwinkel sehen will:
/// - links der Monatskalender an einem Nagel
/// - in der Mitte ein Fenster, das sich mit der Tageszeit ändert
/// - rechts eine Wanduhr und ein Regal
///
/// Die Perspektive ist ein "Bühnenbild": Wand und Tisch erzeugen Tiefe,
/// aber alles mit Text bleibt gerade, damit es gut lesbar ist.
struct WallView: View {
    /// Der aufgeschlagene Tag – der Kalender teilt ihn mit der Unterlage.
    @Binding var selectedDay: Date

    var body: some View {
        HStack(alignment: .top, spacing: 32) {
            HangingCalendar(selectedDay: $selectedDay)
                .frame(width: 300)

            Spacer(minLength: 0)

            WallWindow()
                .frame(width: 260, height: 160)
                .padding(.top, 26)

            Spacer(minLength: 0)

            VStack(spacing: 16) {
                WallClock()
                Shelf()
            }
            .frame(width: 270)
            .padding(.top, 18)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(WallBackground())
    }
}

// MARK: - Wandfläche

/// Warmer Putz, oben etwas heller. Unten fällt der Schatten der Tischplatte auf die Wand.
private struct WallBackground: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(colors: [.wallLight, .wall], startPoint: .top, endPoint: .bottom)
            LinearGradient(colors: [.clear, .black.opacity(0.28)], startPoint: .top, endPoint: .bottom)
                .frame(height: 26)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Kalender am Nagel

/// Der Monatskalender, an einer Schnur an einem Nagel aufgehängt.
private struct HangingCalendar: View {
    @Binding var selectedDay: Date

    var body: some View {
        VStack(spacing: 0) {
            // Die Schnur: vom Nagel schräg zu den beiden oberen Ecken des Kalenders.
            Canvas { context, size in
                let nail = CGPoint(x: size.width / 2, y: 4)
                var string = Path()
                string.move(to: CGPoint(x: size.width * 0.18, y: size.height))
                string.addLine(to: nail)
                string.addLine(to: CGPoint(x: size.width * 0.82, y: size.height))
                context.stroke(string, with: .color(.black.opacity(0.45)), lineWidth: 1)
            }
            .frame(height: 16)
            .overlay(alignment: .top) {
                // Der Nagel
                Circle()
                    .fill(Color(white: 0.45))
                    .frame(width: 7, height: 7)
                    .shadow(color: .black.opacity(0.4), radius: 1, y: 1)
            }
            .accessibilityHidden(true)

            MiniCalendarView(selectedDay: $selectedDay)
        }
    }
}

// MARK: - Fenster

/// Tageszeiten für das Fenster. Die Uhrzeiten sind bewusst einfach gehalten
/// (keine echten Sonnenauf- und -untergänge).
private enum DayPhase {
    case morning, day, evening, night

    init(hour: Int) {
        switch hour {
        case 6..<9: self = .morning
        case 9..<17: self = .day
        case 17..<20: self = .evening
        default: self = .night
        }
    }

    var sky: [Color] {
        switch self {
        case .morning: [Color(red: 0.55, green: 0.70, blue: 0.88), Color(red: 0.98, green: 0.80, blue: 0.62)]
        case .day: [Color(red: 0.36, green: 0.62, blue: 0.90), Color(red: 0.70, green: 0.85, blue: 0.97)]
        case .evening: [Color(red: 0.36, green: 0.30, blue: 0.55), Color(red: 0.96, green: 0.55, blue: 0.35)]
        case .night: [Color(red: 0.05, green: 0.07, blue: 0.18), Color(red: 0.14, green: 0.18, blue: 0.35)]
        }
    }

    /// Sonne bzw. Mond
    var light: Color {
        switch self {
        case .morning: Color(red: 1.0, green: 0.85, blue: 0.55)
        case .day: Color(red: 1.0, green: 0.92, blue: 0.55)
        case .evening: Color(red: 1.0, green: 0.62, blue: 0.35)
        case .night: Color(red: 0.95, green: 0.95, blue: 0.85)
        }
    }

    /// Position von Sonne/Mond im Fenster (0…1 von links/oben)
    var lightPosition: UnitPoint {
        switch self {
        case .morning: UnitPoint(x: 0.22, y: 0.62)
        case .day: UnitPoint(x: 0.72, y: 0.25)
        case .evening: UnitPoint(x: 0.78, y: 0.66)
        case .night: UnitPoint(x: 0.70, y: 0.28)
        }
    }

    /// Die Hügel am Horizont – nachts fast schwarz.
    var hills: Color {
        switch self {
        case .night: Color(red: 0.06, green: 0.10, blue: 0.10)
        case .evening: Color(red: 0.22, green: 0.22, blue: 0.20)
        default: Color(red: 0.35, green: 0.52, blue: 0.33)
        }
    }
}

/// Ein Sprossenfenster mit Fensterbank. Draußen ändert sich der Himmel mit der Uhrzeit.
///
/// `TimelineView` zeichnet die Ansicht in festen Abständen neu – hier jede Minute.
private struct WallWindow: View {
    /// Feste Sternpositionen (0…1), damit die Sterne nicht bei jedem Neuzeichnen springen.
    private let stars: [UnitPoint] = [
        .init(x: 0.10, y: 0.15), .init(x: 0.25, y: 0.35), .init(x: 0.38, y: 0.12),
        .init(x: 0.55, y: 0.40), .init(x: 0.85, y: 0.12), .init(x: 0.92, y: 0.45),
        .init(x: 0.15, y: 0.55), .init(x: 0.47, y: 0.22)
    ]

    var body: some View {
        TimelineView(.everyMinute) { timeline in
            let phase = DayPhase(hour: Calendar.current.component(.hour, from: timeline.date))

            VStack(spacing: 0) {
                GeometryReader { geo in
                    let size = geo.size
                    ZStack {
                        LinearGradient(colors: phase.sky, startPoint: .top, endPoint: .bottom)

                        if phase == .night {
                            ForEach(stars.indices, id: \.self) { i in
                                Circle()
                                    .fill(.white.opacity(0.8))
                                    .frame(width: 2, height: 2)
                                    .position(x: stars[i].x * size.width, y: stars[i].y * size.height)
                            }
                        }

                        Circle()
                            .fill(phase.light)
                            .frame(width: 24, height: 24)
                            .shadow(color: phase.light.opacity(0.8), radius: 10)
                            .position(x: phase.lightPosition.x * size.width,
                                      y: phase.lightPosition.y * size.height)

                        // Hügel am Horizont
                        Ellipse()
                            .fill(phase.hills)
                            .frame(width: size.width * 0.9, height: size.height * 0.45)
                            .position(x: size.width * 0.2, y: size.height * 1.05)
                        Ellipse()
                            .fill(phase.hills.opacity(0.85))
                            .frame(width: size.width, height: size.height * 0.38)
                            .position(x: size.width * 0.8, y: size.height * 1.08)
                    }
                    .clipped()
                    // Fensterkreuz
                    .overlay {
                        ZStack {
                            Rectangle().fill(Color.windowFrame).frame(width: 6)
                            Rectangle().fill(Color.windowFrame).frame(height: 6)
                        }
                    }
                }
                .border(Color.windowFrame, width: 8)

                // Fensterbank
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.windowFrame)
                    .frame(height: 9)
                    .padding(.horizontal, -10)
                    .shadow(color: .black.opacity(0.3), radius: 3, y: 3)
            }
            .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Wanduhr

/// Eine analoge Wanduhr mit Messing-Rand. Sie zeigt die echte Uhrzeit.
private struct WallClock: View {
    var body: some View {
        TimelineView(.everyMinute) { timeline in
            let parts = Calendar.current.dateComponents([.hour, .minute], from: timeline.date)
            let minute = Double(parts.minute ?? 0)
            let hour = Double((parts.hour ?? 0) % 12) + minute / 60

            ZStack {
                Circle().fill(Color.notepadPaper)
                Circle().strokeBorder(Color.brass, lineWidth: 4)

                // 12 Striche; jeder dritte (12, 3, 6, 9) etwas kräftiger
                ForEach(0..<12, id: \.self) { i in
                    Rectangle()
                        .fill(Color.walnutDark)
                        .frame(width: i % 3 == 0 ? 2.5 : 1.2, height: i % 3 == 0 ? 8 : 5)
                        .offset(y: -27)
                        .rotationEffect(.degrees(Double(i) * 30))
                }

                hand(length: 17, width: 3.5, degrees: hour * 30)   // Stundenzeiger
                hand(length: 25, width: 2, degrees: minute * 6)    // Minutenzeiger
                Circle().fill(Color.walnutDark).frame(width: 6, height: 6)
            }
            .frame(width: 74, height: 74)
            .shadow(color: .black.opacity(0.3), radius: 4, y: 3)
            .accessibilityElement()
            .accessibilityLabel("Uhr: \(timeline.date.formatted(date: .omitted, time: .shortened))")
        }
    }

    /// Ein Zeiger: zeigt bei 0 Grad nach oben und wird um die Uhrmitte gedreht.
    private func hand(length: CGFloat, width: CGFloat, degrees: Double) -> some View {
        Capsule()
            .fill(Color.walnutDark)
            .frame(width: width, height: length)
            .offset(y: -length / 2)
            .rotationEffect(.degrees(degrees))
    }
}

// MARK: - Regal

/// Ein Wandregal mit ein paar Büchern und einer Pflanze. (Noch reine Deko.)
private struct Shelf: View {
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom, spacing: 3) {
                book(Color(red: 0.45, green: 0.17, blue: 0.14), width: 14, height: 46)
                book(Color(red: 0.30, green: 0.40, blue: 0.30), width: 12, height: 40)
                book(Color(red: 0.18, green: 0.24, blue: 0.38), width: 16, height: 50)
                book(Color.brassDark, width: 10, height: 38)
                Spacer()
                Plant()
            }
            .padding(.horizontal, 16)

            // Das Brett
            RoundedRectangle(cornerRadius: 2)
                .fill(LinearGradient(colors: [.walnutLight, .walnut], startPoint: .top, endPoint: .bottom))
                .frame(height: 9)
                .shadow(color: .black.opacity(0.35), radius: 4, y: 4)
        }
        .accessibilityHidden(true)
    }

    private func book(_ color: Color, width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 1.5)
            .fill(color)
            .frame(width: width, height: height)
            .overlay(alignment: .top) {
                // Ein heller Streifen auf dem Buchrücken
                Rectangle().fill(.white.opacity(0.25)).frame(height: 2).padding(.top, 6)
            }
    }
}

/// Eine Topfpflanze: Blätter sind gedrehte Ellipsen über einem Messingtopf.
private struct Plant: View {
    private let angles: [Double] = [-55, -28, -8, 14, 35, 58]

    var body: some View {
        VStack(spacing: -4) {
            ZStack(alignment: .bottom) {
                ForEach(angles.indices, id: \.self) { i in
                    Ellipse()
                        .fill(i.isMultiple(of: 2) ? Color(red: 0.28, green: 0.48, blue: 0.25)
                                                  : Color(red: 0.36, green: 0.58, blue: 0.30))
                        .frame(width: 11, height: 30)
                        .rotationEffect(.degrees(angles[i]), anchor: .bottom)
                }
            }
            .frame(width: 60, height: 34)

            PotShape()
                .fill(LinearGradient(colors: [.brass, .brassDark], startPoint: .leading, endPoint: .trailing))
                .frame(width: 30, height: 24)
        }
    }
}

/// Ein Blumentopf: oben breiter als unten.
private struct PotShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.15, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.15, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    WallView(selectedDay: .constant(Calendar.current.startOfDay(for: .now)))
        .modelContainer(for: [TodoItem.self, Note.self], inMemory: true)
        .frame(width: 1280, height: 250)
}
