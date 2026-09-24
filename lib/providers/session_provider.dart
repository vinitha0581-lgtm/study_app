import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/study_session.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';
import '../services/notification_service.dart';

enum TimerMode { pomodoro, customCountdown, stopwatch }
enum PomodoroPhase { work, shortBreak, longBreak }

class SessionProvider with ChangeNotifier {
  final StorageService _storageService;
  final AudioAlertService _audioService = AudioAlertService();
  final NotificationService _notificationService = NotificationService();
  final _uuid = const Uuid();

  List<StudySession> _sessions = [];
  Timer? _timer;

  // Active Timer State
  bool _isRunning = false;
  bool _isPaused = false;
  TimerMode _mode = TimerMode.pomodoro;
  PomodoroPhase _phase = PomodoroPhase.work;
  int _completedPomodoroCycles = 0;

  int _totalSeconds = 25 * 60;
  int _remainingSeconds = 25 * 60;
  int _elapsedStopwatchSeconds = 0;

  String? _activeSubjectId;
  String? _activeScheduleId;
  DateTime? _sessionStartTime;

  SessionProvider(this._storageService) {
    loadSessions();
  }

  // Getters
  List<StudySession> get sessions => _sessions;
  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;
  TimerMode get mode => _mode;
  PomodoroPhase get phase => _phase;
  int get remainingSeconds => _remainingSeconds;
  int get totalSeconds => _totalSeconds;
  int get elapsedStopwatchSeconds => _elapsedStopwatchSeconds;
  int get completedCycles => _completedPomodoroCycles;
  String? get activeSubjectId => _activeSubjectId;
  String? get activeScheduleId => _activeScheduleId;
  double get progressFraction {
    if (_mode == TimerMode.stopwatch) return 1.0;
    if (_totalSeconds <= 0) return 0.0;
    return 1.0 - (_remainingSeconds / _totalSeconds);
  }

  void loadSessions() {
    _sessions = _storageService.getSessions();
    notifyListeners();
  }

  void setupPomodoro({
    required String subjectId,
    String? scheduleId,
    int workMinutes = 25,
  }) {
    if (_isRunning) stopTimer(saveSession: false);
    _mode = TimerMode.pomodoro;
    _phase = PomodoroPhase.work;
    _activeSubjectId = subjectId;
    _activeScheduleId = scheduleId;
    _totalSeconds = workMinutes * 60;
    _remainingSeconds = _totalSeconds;
    _isPaused = false;
    notifyListeners();
  }

  void setupCustomCountdown({
    required String subjectId,
    String? scheduleId,
    required int minutes,
  }) {
    if (_isRunning) stopTimer(saveSession: false);
    _mode = TimerMode.customCountdown;
    _phase = PomodoroPhase.work;
    _activeSubjectId = subjectId;
    _activeScheduleId = scheduleId;
    _totalSeconds = minutes * 60;
    _remainingSeconds = _totalSeconds;
    _isPaused = false;
    notifyListeners();
  }

  void startTimer() {
    if (_isRunning && !_isPaused) return;

    if (!_isPaused) {
      _sessionStartTime = DateTime.now();
      _audioService.playStartSessionSound();
    }

    _isRunning = true;
    _isPaused = false;
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_mode == TimerMode.stopwatch) {
        _elapsedStopwatchSeconds++;
        notifyListeners();
      } else {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
          notifyListeners();
        } else {
          _handleTimerFinished();
        }
      }
    });
    notifyListeners();
  }

  void pauseTimer() {
    if (!_isRunning || _isPaused) return;
    _timer?.cancel();
    _isPaused = true;
    notifyListeners();
  }

  void resumeTimer() {
    if (!_isPaused) return;
    startTimer();
  }

  Future<void> stopTimer({bool saveSession = true}) async {
    _timer?.cancel();
    if (saveSession && _sessionStartTime != null && _activeSubjectId != null) {
      final durationMins = (_totalSeconds - _remainingSeconds) ~/ 60;
      if (durationMins > 0 || _mode == TimerMode.stopwatch) {
        final actualMins = _mode == TimerMode.stopwatch
            ? (_elapsedStopwatchSeconds ~/ 60)
            : durationMins;
        if (actualMins > 0) {
          await _recordSession(
            subjectId: _activeSubjectId!,
            scheduleId: _activeScheduleId,
            startTime: _sessionStartTime!,
            endTime: DateTime.now(),
            durationMinutes: actualMins,
            type: _mode == TimerMode.pomodoro
                ? SessionType.pomodoro
                : (_activeScheduleId != null
                    ? SessionType.scheduled
                    : SessionType.custom),
          );
        }
      }
    }

    _isRunning = false;
    _isPaused = false;
    _sessionStartTime = null;
    _remainingSeconds = _totalSeconds;
    _elapsedStopwatchSeconds = 0;
    notifyListeners();
  }

  void _handleTimerFinished() {
    _timer?.cancel();
    _audioService.playTimerCompleteSound();

    if (_mode == TimerMode.pomodoro) {
      if (_phase == PomodoroPhase.work) {
        _completedPomodoroCycles++;
        // Log study session
        if (_activeSubjectId != null && _sessionStartTime != null) {
          _recordSession(
            subjectId: _activeSubjectId!,
            scheduleId: _activeScheduleId,
            startTime: _sessionStartTime!,
            endTime: DateTime.now(),
            durationMinutes: _totalSeconds ~/ 60,
            type: SessionType.pomodoro,
          );
        }
        _notificationService.showInstantNotification(
          title: '🎯 Great Job! Focus Session Done!',
          body: 'Take a well-deserved break now.',
        );

        // Transition to short or long break
        if (_completedPomodoroCycles % 4 == 0) {
          _phase = PomodoroPhase.longBreak;
          _totalSeconds = 15 * 60;
        } else {
          _phase = PomodoroPhase.shortBreak;
          _totalSeconds = 5 * 60;
        }
      } else {
        // Break finished, return to work
        _audioService.playBreakSound();
        _notificationService.showInstantNotification(
          title: '⚡ Break Finished!',
          body: 'Ready to start your next study interval?',
        );
        _phase = PomodoroPhase.work;
        _totalSeconds = 25 * 60;
      }
      _remainingSeconds = _totalSeconds;
      _isRunning = false;
      _isPaused = false;
      _sessionStartTime = null;
    } else {
      // Custom timer finished
      if (_activeSubjectId != null && _sessionStartTime != null) {
        _recordSession(
          subjectId: _activeSubjectId!,
          scheduleId: _activeScheduleId,
          startTime: _sessionStartTime!,
          endTime: DateTime.now(),
          durationMinutes: _totalSeconds ~/ 60,
          type: _activeScheduleId != null
              ? SessionType.scheduled
              : SessionType.custom,
        );
      }
      _notificationService.showInstantNotification(
        title: '🏁 Study Session Finished!',
        body: 'Awesome work completing your session. Write down your notes!',
      );
      _isRunning = false;
      _isPaused = false;
      _remainingSeconds = _totalSeconds;
      _sessionStartTime = null;
    }

    notifyListeners();
  }

  Future<void> _recordSession({
    required String subjectId,
    String? scheduleId,
    required DateTime startTime,
    required DateTime endTime,
    required int durationMinutes,
    required SessionType type,
  }) async {
    final session = StudySession(
      id: _uuid.v4(),
      subjectId: subjectId,
      scheduleId: scheduleId,
      startTime: startTime,
      endTime: endTime,
      durationMinutes: durationMinutes,
      type: type,
      isCompleted: true,
    );
    _sessions.insert(0, session);
    await _storageService.saveSessions(_sessions);
    notifyListeners();
  }

  // Analytics helpers
  int get todayStudyMinutes {
    final now = DateTime.now();
    return _sessions
        .where((s) =>
            s.startTime.year == now.year &&
            s.startTime.month == now.month &&
            s.startTime.day == now.day)
        .fold(0, (sum, s) => sum + s.durationMinutes);
  }

  int get thisWeekStudyMinutes {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final cleanStart =
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    return _sessions
        .where((s) => s.startTime.isAfter(cleanStart))
        .fold(0, (sum, s) => sum + s.durationMinutes);
  }

  int get currentStreakDays {
    if (_sessions.isEmpty) return 0;
    int streak = 0;
    DateTime checkDate = DateTime.now();

    while (true) {
      final hasSession = _sessions.any((s) =>
          s.startTime.year == checkDate.year &&
          s.startTime.month == checkDate.month &&
          s.startTime.day == checkDate.day);

      if (hasSession) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        if (streak == 0 &&
            checkDate.day == DateTime.now().day &&
            checkDate.month == DateTime.now().month &&
            checkDate.year == DateTime.now().year) {
          // If haven't studied today yet, check yesterday to preserve ongoing streak
          checkDate = checkDate.subtract(const Duration(days: 1));
          continue;
        }
        break;
      }
    }
    return streak;
  }

  Map<String, int> getMinutesPerSubject() {
    final Map<String, int> map = {};
    for (final s in _sessions) {
      map[s.subjectId] = (map[s.subjectId] ?? 0) + s.durationMinutes;
    }
    return map;
  }
}
