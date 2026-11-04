import SwiftUI
import SwiftData

/// Die Hauptansicht der App: der Schreibtisch.
///
/// Aufteilung auf der Holzplatte:
/// - links: Monatskalender und Klebezettel (Notizen mit optionaler Erinnerung)
/// - Mitte: die Schreibunterlage mit dem Tagesblatt (To-Dos + Notizen zum Tag)
/// - rechts: die Tablettenbox (Supplements)
///
/// Unter den Klebezetteln und der Tablettenbox ist bewusst Platz frei –
/// dort können später weitere Dinge auf den Tisch (z. B. Wasserglas, Pflanze).
struct ContentView: View {
    /// Der aufgeschlagene Tag. Er liegt hier, damit Kalender und Unterlage ihn teilen.
    @State private var day = Calendar.current.startOfDay(for: .now)

    var body: some View {
        HStack(alignment: .top, spacing: 32) {
            // Linke Tischseite
            VStack(spacing: 24) {
                MiniCalendarView(selectedDay: $day)
                NoteListView()
            }
            .frame(width: 250)

            // Mitte: die Unterlage
            DayPageView(day: $day)
                .environment(\.colorScheme, .light) // Papier bleibt hell
                .frame(minWidth: 520, maxWidth: .infinity, maxHeight: .infinity)

            // Rechte Tischseite
            VStack(spacing: 24) {
                SupplementTrackerView()
                // Platz für später (z. B. Wasserglas, Sanduhr, Pflanze)
                Spacer(minLength: 0)
            }
            .frame(width: 270)
        }
        .padding(.horizontal, 32)
        .padding(.top, 44)
        .padding(.bottom, 32)
        .background(DeskBackground())
        .frame(minWidth: 1180, minHeight: 680)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [TodoItem.self, DayNote.self, Note.self, Supplement.self, SupplementIntake.self], inMemory: true)
}
