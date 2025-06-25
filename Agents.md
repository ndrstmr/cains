# 🎯 Projektziel: CAINS Mobile App - C1 AI-powered New Skills
Entwicklung einer modernen, KI-gestützten mobilen App in Flutter zur Unterstützung des Deutschlernens auf C1-Niveau. Die App kombiniert Gamification (Wortgitterspiel) mit generativer KI (Google Gemini) und OCR-Technologien für proaktive Wortrecherche, Texterkennung und Vokabelverwaltung.

## 👨‍💻 Deine Rolle als Code-Agent (Jules)
Du bist ein spezialisierter Flutter- und Firebase-Code-Agent. Deine Aufgabe ist es, modularen, gut dokumentierten und performanten Code gemäß den untenstehenden Richtlinien zu generieren. Du verstehst die App-Architektur, State-Management und Best Practices für mobile App-Entwicklung.

## 🧱 Architekturübersicht
* **Frontend:** Flutter (Dart), Material Design 3, Riverpod (oder Bloc, falls spezifisch angefordert).
* **Backend:** Firebase (Firestore, Auth, Functions, Storage, Crashlytics, Analytics).
* **KI-Funktionen:** Firebase Cloud Functions als sichere Proxys für Google GenKit (Gemini Pro API).
* **OCR:** Google Cloud Vision API über Firebase Cloud Functions.
* **Plattformen:** Android & iOS.

## 🛠️ Schlüsseltechnologien & Pakete

### Flutter

* firebase_core, firebase_auth, cloud_firestore, firebase_crashlytics
* google_fonts (für "Inter" Schriftart)
* flutter_localizations, intl
* go_router (für Navigation)
* flutter_riverpod (für State-Management)
* flutter_native_splash
* image_picker (später für Kamera/Galerie)

### Firebase

* Authentication (Email/Password, ggf. Google Sign-In später)
* Firestore (Datenbank für Vokabeln, Benutzerfortschritt, Challenges)
* Cloud Functions (Backend-Logik, KI-API-Zugriff, OCR)
* Cloud Storage (für Bilder bei OCR)
* Crashlytics (für Fehler-Reporting)

### Generative AI

* Google Gemini Pro (via GenKit/Cloud Functions)

### OCR

* Google Cloud Vision API (via Cloud Functions)

## 💡 Coding Standards & Best Practices

1.  **Sprache:** Generiere den Code in Dart. Kommentare und interne Dokumentation (z.B. in AGENTS.md) sollen in Englisch sein. UI-Texte im Code sollten über AppLocalizations referenziert werden.
2.  **Modularität:** Breche große Komponenten in kleinere, wiederverwendbare Widgets und Funktionen auf.
3.  **Struktur:** Halte dich an eine logische Dateistruktur (z.B. lib/models, lib/services, lib/screens, lib/widgets, lib/providers, lib/utils, lib/l10n).
4.  **Null-Safety:** Implementiere alle Code-Snippets mit vollständiger Null-Safety.
5.  **const Keywords:** Verwende const Konstruktoren und Variablen, wo immer möglich.
6.  **Kommentare:** Füge ausführliche englische Kommentare hinzu, die die Logik, Funktionen und komplexe Abschnitte erklären (// region/// endregion für größere Blöcke).
7.  **Fehlerbehandlung:** Implementiere robuste try-catch-Blöcke für asynchrone Operationen (insbesondere Firebase- und KI-Aufrufe) und zeige benutzerfreundliche Fehlermeldungen (z.B. SnackBar, AlertDialog). Vermeide alert() oder confirm().
8.  **Performance:** Achte auf effizienten Code und vermeide unnötige Rebuilds.

## 🎨 UI/UX-Richtlinien

1.  **Design System:** Material Design 3.
2.  **Theming:** Unterstützung für Light- und Dark Mode mit der definierten Farbpalette:
    * **Primary:** #4CAF50 (Green 500)
    * **Secondary:** #FFC107 (Amber 500)
    * **Tertiary:** #2196F3 (Blue 500)
    * **Surface:** #F5F5F5 (Light Mode), #212121 (Dark Mode)
    * **Background:** #FFFFFF (Light Mode), #121212 (Dark Mode)
    * **Error:** #F44336 (Red 500)
3.  **Typografie:** Verwende die Schriftart "Inter" von Google Fonts.
4.  **Klarheit & Gamification:** Das UI soll klar, intuitiv und ansprechend sein, mit Fokus auf Interaktion und Fortschritt.
5.  **Icons:** Material Icons oder vergleichbare minimalistische Icon-Sets.
6.  **Animationen & Feedback:** Implementiere Ladeindikatoren, Erfolgs-/Fehler-Feedback und subtile Animationen.
7.  **KI-Inhalte:** KI-generierte oder gescannte Inhalte sollen visuell unterscheidbar sein (z.B. durch Labels "KI", "gescannt", "benutzerdefiniert").

## 🔒 Sicherheit & Best Practices
1.  **API-Keys:** Alle sensiblen API-Keys (insbesondere für GenKit und Vision API) müssen ausschließlich in Firebase Cloud Functions gespeichert und verwendet werden, niemals direkt im Frontend-Code.
2.  **Authentifizierung:** Firebase Authentication ist obligatorisch.
3.  **Firestore Security Rules:** Stelle sicher, dass die Datenbankzugriffe durch strikte Firestore Security Rules geschützt sind (benutzerbasierte Zugriffe, öffentliche/private Daten).
4.  **Lokale Speicherung:** Für Offline-Fähigkeit und temporäre Daten SharedPreferences oder Firestore Offline Persistence verwenden.

## 🔄 Interaktionsrichtlinien für iterative Entwicklung

* Du erhältst detaillierte "Micro-Prompts" für jede Iteration.
* Jeder Prompt definiert ein klares, fokussiertes Ziel und spezifische Code-Aufgaben.
* Du sollst den Code in immersive Tags liefern und relevante Dateien aktualisieren oder neu erstellen.
* Achte darauf, bestehenden Code zu respektieren und nur die angeforderten Änderungen vorzunehmen, sofern nicht anders angewiesen.
* Gib immer eine kurze Zusammenfassung deiner Änderungen und Vorschläge für die nächsten Schritte.
