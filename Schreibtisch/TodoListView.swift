import SwiftUI
import SwiftData

/// Die To-Do-Liste: Aufgaben anlegen, abhaken und löschen.
///
/// Die Ansicht ist in sich abgeschlossen. Später kann sie einfach als
/// Kachel ins Schreibtisch-Dashboard gesetzt werden.
struct TodoListView: View {
    /// `@Environment(\.modelContext)` gibt uns Zugriff auf den Speicher.
    /// Darüber fügen wir Aufgaben hinzu oder löschen sie.
    @Environment(\.modelContext) private var modelContext

    /// `@Query` holt alle gespeicherten Aufgaben und hält die Liste
    /// automatisch aktuell, sobald sich etwas ändert.
    /// Sortiert nach Erstellungsdatum (älteste oben).
    @Query(sort: \TodoItem.createdAt) private var allTodos: [TodoItem]

    /// Offene Aufgaben zuerst, erledigte rutschen nach unten.
    /// (SwiftData kann nicht direkt nach Ja/Nein-Werten sortieren,
    /// darum machen wir diesen Schritt selbst.)
    private var todos: [TodoItem] {
        allTodos.filter { !$0.isDone } + allTodos.filter { $0.isDone }
    }

    /// Der Text im Eingabefeld für eine neue Aufgabe.
    @State private var newTitle = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("To-Dos")
                .font(.title2.bold())

            // Eingabezeile für neue Aufgaben
            HStack {
                TextField("Neue Aufgabe …", text: $newTitle)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(addTodo) // Enter-Taste fügt hinzu

                Button("Hinzufügen", systemImage: "plus", action: addTodo)
                    .disabled(trimmedTitle.isEmpty)
            }

            if todos.isEmpty {
                ContentUnavailableView(
                    "Keine Aufgaben",
                    systemImage: "checklist",
                    description: Text("Lege oben deine erste Aufgabe an.")
                )
            } else {
                List {
                    ForEach(todos) { todo in
                        TodoRow(todo: todo, onDelete: { delete(todo) })
                    }
                    .onDelete(perform: delete)
                }
                .listStyle(.inset)
                .scrollContentBackground(.hidden) // Papier der Karte scheint durch
            }
        }
        .padding()
    }

    private var trimmedTitle: String {
        newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func addTodo() {
        guard !trimmedTitle.isEmpty else { return }
        modelContext.insert(TodoItem(title: trimmedTitle))
        newTitle = ""
    }

    private func delete(_ todo: TodoItem) {
        modelContext.delete(todo)
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(todos[index])
        }
    }
}

/// Eine Zeile in der Liste: Haken, Titel und Löschen-Knopf.
private struct TodoRow: View {
    /// `@Bindable` erlaubt es, Eigenschaften des gespeicherten Objekts
    /// direkt zu ändern (z. B. `isDone`). SwiftData speichert das automatisch.
    @Bindable var todo: TodoItem
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Toggle(isOn: $todo.isDone) {
                Text(todo.title)
                    .strikethrough(todo.isDone)
                    .foregroundStyle(todo.isDone ? .secondary : .primary)
            }
            .toggleStyle(.checkbox)

            Spacer()

            Button("Löschen", systemImage: "trash", role: .destructive, action: onDelete)
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
        }
        .contextMenu {
            Button("Löschen", role: .destructive, action: onDelete)
        }
    }
}

#Preview {
    TodoListView()
        // Für die Vorschau: ein Speicher nur im Arbeitsspeicher (nicht auf der Festplatte).
        .modelContainer(for: TodoItem.self, inMemory: true)
        .frame(width: 400, height: 400)
}
