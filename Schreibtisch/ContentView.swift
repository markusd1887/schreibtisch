import SwiftUI
import SwiftData

/// Die Hauptansicht der App: der Schreibtisch mit der Wand dahinter.
///
/// Oben die Wand (`WallView`): Monatskalender, Fenster, Uhr und Regal.
///
/// Unten die Tischplatte:
/// - links: Klebezettel (Notizen mit optionaler Erinnerung)
/// - Mitte: die Lederunterlage mit dem Tagesblatt (To-Dos + Notizen zum Tag)
/// - rechts: die Tablettenbox (Supplements)
///
/// Unter der Tablettenbox ist bewusst Platz frei –
/// dort können später weitere Dinge auf den Tisch (z. B. Wasserglas, Sanduhr).
struct ContentView: View {
    /// Der aufgeschlagene Tag. Er liegt hier, damit Kalender und Unterlage ihn teilen.
    @State private var day = Calendar.current.startOfDay(for: .now)

    /// Höhe der Wand. Bewusst niedrig gehalten, damit auch auf einem
    /// MacBook-Bildschirm genug Platz für den Schreibtisch bleibt.
    private let wallHeight: CGFloat = 250

    var body: some View {
        VStack(spacing: 0) {
            WallView(selectedDay: $day)
                .frame(height: wallHeight)
            desk
        }
        .frame(minWidth: 1180, minHeight: 780)
    }

    /// Die Tischplatte mit allem, was darauf liegt.
    private var desk: some View {
        HStack(alignment: .top, spacing: 32) {
            // Linke Tischseite
            NoteListView()
                .frame(width: 250)

            // Mitte: die Unterlage
            DayPageView(day: $day)
                .environment(\.colorScheme, .light) // Papier bleibt hell
                .padding(18)
                .background(LeatherPad()) // Die Lederunterlage unter dem Block
                .frame(minWidth: 520, maxWidth: .infinity, maxHeight: .infinity)

            // Rechte Tischseite
            VStack(spacing: 24) {
                SupplementTrackerView()
                // Platz für später (z. B. Wasserglas, Sanduhr)
                Spacer(minLength: 0)
            }
            .frame(width: 270)
        }
        .padding(.horizontal, 32)
        .padding(.top, 26)
        .padding(.bottom, 28)
        .background(DeskBackground())
        .overlay(alignment: .top) { DeskEdge() }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [TodoItem.self, DayNote.self, Note.self, Supplement.self, SupplementIntake.self], inMemory: true)
}
