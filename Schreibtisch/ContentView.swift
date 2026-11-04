import SwiftUI
import SwiftData

/// Die Hauptansicht der App.
/// Später wird hier das Schreibtisch-Dashboard mit mehreren Kacheln stehen.
/// Vorerst zeigen wir To-Dos und Notizen einfach nebeneinander.
struct ContentView: View {
    var body: some View {
        HStack(spacing: 0) {
            TodoListView()
            Divider()
            NoteListView()
        }
        .frame(minWidth: 800, minHeight: 450)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [TodoItem.self, Note.self], inMemory: true)
}
