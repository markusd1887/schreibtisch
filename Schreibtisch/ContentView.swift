import SwiftUI
import SwiftData

/// Die Hauptansicht der App: das Schreibtisch-Dashboard.
///
/// Auf einer Holzplatte liegen drei "Papiere":
/// ein Notizblock (To-Dos), ein Klebezettel (Notizen) und ein Klemmbrett (Supplements).
/// Wie sie aussehen, steht in `DeskStyle.swift`.
struct ContentView: View {
    var body: some View {
        HStack(alignment: .top, spacing: 36) {
            DeskCard(paper: .notepadPaper, decoration: .pin) {
                TodoListView()
            }

            DeskCard(paper: .stickyNoteYellow, decoration: .tape) {
                NoteListView()
            }

            DeskCard(paper: .clipboardPaper, decoration: .clip) {
                SupplementTrackerView()
            }
        }
        .padding(.horizontal, 36)
        .padding(.top, 48)
        .padding(.bottom, 36)
        .background(DeskBackground())
        .frame(minWidth: 1200, minHeight: 520)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [TodoItem.self, Note.self, Supplement.self, SupplementIntake.self], inMemory: true)
}
