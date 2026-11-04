import SwiftUI
import SwiftData

/// Die Hauptansicht der App.
/// Später wird hier das Schreibtisch-Dashboard mit mehreren Kacheln stehen.
/// Vorerst zeigen wir nur die To-Do-Liste.
struct ContentView: View {
    var body: some View {
        TodoListView()
            .frame(minWidth: 400, minHeight: 400)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: TodoItem.self, inMemory: true)
}
