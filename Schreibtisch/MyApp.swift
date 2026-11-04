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
        // Später kommt hier noch das Supplement-Modell dazu.
        .modelContainer(for: [TodoItem.self, Note.self])
    }
}
