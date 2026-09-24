# 📚 StudyFlow - Study Progress & Schedule Tracker

A complete, modern **Study Progress Tracker App** featuring **recurring study time scheduling**, **notification alarms & sound chimes**, **focus timer with Pomodoro technique**, and **rich Markdown note taking with interactive checklists**.

---

## 🌟 Key Features

1. **Study Time Scheduling & Recurring Alarms**
   - Configure specific start & end times for each subject.
   - Set recurring days of the week (e.g. Mon-Fri or custom days).
   - Set proactive reminders (e.g., 5, 10, 15, or 30 minutes before session starts).
   - Quick toggle switch to mute or activate individual schedules.

2. **Notifications & Sound Alerts**
   - **Desktop / Mobile Notifications**: Get notified with high priority alerts when it's time to study.
   - **Audio Chimes**: Synthesized bell chimes and sound effects for session starts, completions, and break intervals.
   - Test notification button to verify sound & notification permissions.

3. **Study Timer & Pomodoro**
   - **Pomodoro Mode (25/5/15)**: Focus intervals with automated short breaks and long break cycles.
   - **Custom Focus Mode**: Pick custom durations (15m, 30m, 45m, 60m, 90m, or exact schedule duration).
   - Live circular progress countdown with active pulsing glow and phase badges.
   - One-click launch from upcoming schedules.

4. **Study Notes & Checklists**
   - Take structured notes linked directly to your study schedules.
   - **Rich Markdown**: Write code snippets, math formulas, bold headers, and quotes.
   - **Interactive Checklists**: Add bullet topics and mark items studied in real time with progress bars.
   - Tagging & subject filtering to easily search through past study insights.

5. **Analytics & Progress Tracking**
   - Daily and weekly study duration charts.
   - Time spent per subject breakdown.
   - Study streak tracker to maintain consistency.
   - Weekly goal targets and completion percentages.

---

## 📁 Project Structure

```
study_tracker_app/
├── lib/                               # Flutter App Source Code
│   ├── main.dart                      # App entrypoint, Provider setup & Themes
│   ├── models/
│   │   ├── subject.dart               # Subject & color categories
│   │   ├── study_schedule.dart        # Recurring schedule data model
│   │   ├── study_session.dart         # Completed sessions & durations
│   │   └── study_note.dart            # Markdown notes & checklist items
│   ├── services/
│   │   ├── storage_service.dart       # Local persistence
│   │   ├── notification_service.dart  # Flutter local notifications
│   │   └── audio_service.dart         # Sound alerts & chimes
│   ├── providers/
│   │   ├── schedule_provider.dart     # Schedule state management
│   │   ├── session_provider.dart      # Timer & Pomodoro state machine
│   │   ├── notes_provider.dart        # Notes & checklist state
│   │   └── theme_provider.dart        # Dark / Light mode
│   ├── screens/
│   │   ├── main_navigation_screen.dart# Bottom tab navigation
│   │   ├── dashboard_screen.dart      # Daily overview & upcoming sessions
│   │   ├── schedule_screen.dart       # Schedule manager & time pickers
│   │   ├── timer_screen.dart          # Live Pomodoro focus timer
│   │   ├── notes_screen.dart          # Filterable notes & search
│   │   ├── note_editor_screen.dart    # Full Markdown editor & preview
│   │   └── analytics_screen.dart      # Charts & goal progress
│   └── widgets/
│       ├── circular_progress_timer.dart
│       ├── schedule_card.dart
│       ├── note_card.dart
│       ├── subject_badge.dart
│       └── quick_note_dialog.dart
├── web_runner/                        # Instant Web / PWA version
│   ├── index.html                     # Responsive UI (Tailwind + Lucide)
│   ├── styles.css                     # Custom styling & animations
│   ├── app.js                         # Web audio synthesizer & notifications
│   └── serve.py                       # Local server launcher
└── pubspec.yaml                       # Flutter dependencies
```

---

## 🚀 How to Run

### Option 1: Instant Browser / Web Version
To run and test the app immediately in your browser:
```bash
python3 /home/sreedev/study_tracker_app/web_runner/serve.py
```
Then open your browser to **http://localhost:8080**.

### Option 2: Flutter (Mobile / Desktop)
Once Flutter SDK is available on your machine:
```bash
cd /home/sreedev/study_tracker_app
flutter pub get
flutter run
```
