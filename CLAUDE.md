# Schreibtisch

## Was ist die App?
"Schreibtisch" ist eine macOS-App: ein persönliches Dashboard im Schreibtisch-Look.
Funktionen:
- **To-Dos** – Aufgaben anlegen, abhaken, löschen
- **Notizen / Erinnerungen** – Notizen schreiben, optional mit Erinnerung zu einem Zeitpunkt
- **Supplement-Tracker** – Einnahme von Supplements morgens / mittags / abends erfassen und abhaken

## Technik
- Sprache: **Swift**
- Oberfläche: **SwiftUI** (macOS)
- Datenspeicherung: **SwiftData** (lokal auf dem Mac)
- Erinnerungen: **UserNotifications** (lokale Mitteilungen)
- Alles läuft **lokal** – kein Server, kein Account, keine Cloud
- Projekt: `Schreibtisch.xcodeproj`, Quellcode im Ordner `Schreibtisch/`

## Arbeitsweise (wichtig!)
Der Entwickler ist **Einsteiger**. Deshalb:
1. **Erst eine Empfehlung nennen**, statt viele Optionen aufzuzählen.
2. **Fachbegriffe kurz erklären**, wenn sie zum ersten Mal vorkommen.
3. **Kleine Schritte** – lieber eine Funktion nach der anderen.
4. **Vor Änderungen kurz den Plan zeigen** (was wird geändert und warum).
5. **Nach jeder funktionierenden Funktion committen** (Git-Commit mit verständlicher Nachricht) und danach `git push`.
6. Antworten auf **Deutsch**.
7. **Klicktest durch den Nutzer**: Claude kann die App nicht selbst bedienen. Nach sichtbaren Änderungen den Nutzer die App ausprobieren lassen und erst nach seinem OK committen.

## Mehrere Aufgaben gleichzeitig
Der Nutzer schreibt oft einen längeren Prompt mit mehreren Wünschen. Dann:
- Den Prompt in einzelne Aufgaben aufteilen und jede an die passende Sitzung geben (oder eine neue starten).
- **Parallel** nur Aufgaben, die **verschiedene Dateien** betreffen. Alle Sitzungen arbeiten im selben Ordner – zwei Sitzungen dürfen nie gleichzeitig dieselbe Datei ändern.
- Aufgaben, die dieselben Dateien betreffen oder alles betreffen (z. B. Look, Farben), **nacheinander**.
- Dem Nutzer jedes Mal sagen, was gleichzeitig läuft und was wartet.
- Jede Sitzung committet nur ihre eigenen Dateien (`git add <dateien>`, nicht `git add -A`).
- Keine Worktrees (getrennte Projektkopien) – zu kompliziert für den Anfang.

## Anbindung an Apple-Kalender (EventKit)
Ziel: Am Mac alles in dieser App erledigen und unterwegs dieselben Daten auf dem iPhone haben.
- **Tischkalender** (`DeskCalendarView`, links auf dem Tisch) zeigt die echten Termine aus dem Mac-Kalender über **EventKit** (`CalendarStore`). iCloud synchronisiert automatisch mit dem iPhone. Termine werden **nicht** in SwiftData gespeichert.
- Die Kalender-Abfrage von macOS kommt erst, wenn der Nutzer auf „Kalender verbinden“ klickt. Nie automatisch beim Start oder in Test-/Vorschau-Programmen auslösen.
- Nächste Schritte: (2) Termine über einen +-Knopf anlegen, (3) evtl. Markierungen im Wandkalender bzw. Termine auf dem Tagesblatt.

## Später geplant (noch nicht umsetzen!)
- **To-Dos → App „Erinnerungen“**: Die To-Dos werden später über EventKit in den Apple-Erinnerungen gespeichert statt in SwiftData. Deshalb jetzt an den To-Dos vor allem Optik und Bedienung ausbauen, nicht das SwiftData-Datenmodell aufwendig erweitern.
- **Notizen** bleiben in der App (SwiftData). Für Apple Notizen gibt es keine offizielle Schnittstelle.
- Das passt weiter zu „alles lokal“: kein eigener Server, die Daten laufen nur über den iCloud-Account des Nutzers.
