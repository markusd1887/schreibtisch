import SwiftUI
import SwiftData

@main struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // `modelContainer` richtet den SwiftData-Speicher für die ganze App ein.
        // Alle Ansichten darin können damit Daten lesen und speichern.
        // Später kommen hier weitere Modelle dazu (Notizen, Supplements).
        .modelContainer(for: TodoItem.self)
    }
}
