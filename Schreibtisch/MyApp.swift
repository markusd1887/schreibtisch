import SwiftUI
import SwiftData
import UserNotifications

@main struct MyApp: App {
    /// Muss dauerhaft gespeichert bleiben, weil die Mitteilungszentrale
    /// ihren "Delegate" (Helfer) nur schwach festhält.
    private let notificationDelegate = NotificationDelegate()

    init() {
        UNUserNotificationCenter.current().delegate = notificationDelegate
        ReminderScheduler.requestAuthorization()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // `modelContainer` richtet den SwiftData-Speicher für die ganze App ein.
        // Alle Ansichten darin können damit Daten lesen und speichern.
        // Für jede Funktion ist hier ihr Modell eingetragen.
        .modelContainer(for: [TodoItem.self, Note.self, Supplement.self, SupplementIntake.self])
    }
}
