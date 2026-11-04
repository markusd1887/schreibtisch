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
        // Keine graue Titelleiste – das Holz reicht bis ganz nach oben.
        .windowStyle(.hiddenTitleBar)
        // Das Fenster lässt sich trotzdem verschieben, indem man aufs Holz klickt und zieht.
        .windowBackgroundDragBehavior(.enabled)
        // `modelContainer` richtet den SwiftData-Speicher für die ganze App ein.
        // Alle Ansichten darin können damit Daten lesen und speichern.
        // Für jede Funktion ist hier ihr Modell eingetragen.
        .modelContainer(for: [TodoItem.self, Note.self, Supplement.self, SupplementIntake.self])
    }
}
