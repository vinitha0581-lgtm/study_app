import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subject.dart';
import '../models/study_schedule.dart';
import '../models/study_session.dart';
import '../models/study_note.dart';

class StorageService {
  static const String _subjectsKey = 'study_subjects_v1';
  static const String _schedulesKey = 'study_schedules_v1';
  static const String _sessionsKey = 'study_sessions_v1';
  static const String _notesKey = 'study_notes_v1';
  static const String _settingsKey = 'study_settings_v1';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _seedDefaultDataIfNeeded();
  }

  Future<void> _seedDefaultDataIfNeeded() async {
    if (!_prefs.containsKey(_subjectsKey)) {
      final defaultSubjects = [
        Subject(
          id: 'sub_1',
          name: 'Mathematics',
          colorValue: 0xFF6366F1, // Indigo
          iconName: 'calculate',
          targetMinutesPerWeek: 300,
        ),
        Subject(
          id: 'sub_2',
          name: 'Computer Science',
          colorValue: 0xFF06B6D4, // Cyan
          iconName: 'code',
          targetMinutesPerWeek: 420,
        ),
        Subject(
          id: 'sub_3',
          name: 'Physics & Engineering',
          colorValue: 0xFF8B5CF6, // Purple
          iconName: 'science',
          targetMinutesPerWeek: 240,
        ),
        Subject(
          id: 'sub_4',
          name: 'General Reading & Prep',
          colorValue: 0xFF10B981, // Emerald
          iconName: 'menu_book',
          targetMinutesPerWeek: 180,
        ),
      ];
      await saveSubjects(defaultSubjects);
    }

    if (!_prefs.containsKey(_schedulesKey)) {
      final defaultSchedules = [
        StudySchedule(
          id: 'sch_1',
          subjectId: 'sub_2',
          title: 'Algorithms & Data Structures',
          startTime: const TimeOfDay(hour: 9, minute: 0),
          endTime: const TimeOfDay(hour: 10, minute: 30),
          daysOfWeek: [1, 2, 3, 4, 5], // Mon - Fri
          reminderMinutesBefore: 10,
          description: 'Focus on Graph Algorithms and LeetCode practice.',
        ),
        StudySchedule(
          id: 'sch_2',
          subjectId: 'sub_1',
          title: 'Linear Algebra & Calculus',
          startTime: const TimeOfDay(hour: 17, minute: 0),
          endTime: const TimeOfDay(hour: 18, minute: 30),
          daysOfWeek: [1, 3, 5], // Mon, Wed, Fri
          reminderMinutesBefore: 15,
          description: 'Eigenvalues, Vector Spaces, Matrix Decomposition.',
        ),
      ];
      await saveSchedules(defaultSchedules);
    }
  }

  // Subjects
  List<Subject> getSubjects() {
    final raw = _prefs.getString(_subjectsKey);
    if (raw == null) return [];
    final List<dynamic> list = jsonDecode(raw);
    return list.map((e) => Subject.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveSubjects(List<Subject> subjects) async {
    final data = jsonEncode(subjects.map((s) => s.toJson()).toList());
    await _prefs.setString(_subjectsKey, data);
  }

  // Schedules
  List<StudySchedule> getSchedules() {
    final raw = _prefs.getString(_schedulesKey);
    if (raw == null) return [];
    final List<dynamic> list = jsonDecode(raw);
    return list
        .map((e) => StudySchedule.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveSchedules(List<StudySchedule> schedules) async {
    final data = jsonEncode(schedules.map((s) => s.toJson()).toList());
    await _prefs.setString(_schedulesKey, data);
  }

  // Sessions
  List<StudySession> getSessions() {
    final raw = _prefs.getString(_sessionsKey);
    if (raw == null) return [];
    final List<dynamic> list = jsonDecode(raw);
    return list
        .map((e) => StudySession.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveSessions(List<StudySession> sessions) async {
    final data = jsonEncode(sessions.map((s) => s.toJson()).toList());
    await _prefs.setString(_sessionsKey, data);
  }

  // Notes
  List<StudyNote> getNotes() {
    final raw = _prefs.getString(_notesKey);
    if (raw == null) return [];
    final List<dynamic> list = jsonDecode(raw);
    return list
        .map((e) => StudyNote.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveNotes(List<StudyNote> notes) async {
    final data = jsonEncode(notes.map((n) => n.toJson()).toList());
    await _prefs.setString(_notesKey, data);
  }

  // Settings
  Map<String, dynamic> getSettings() {
    final raw = _prefs.getString(_settingsKey);
    if (raw == null) {
      return {
        'pomodoroDuration': 25,
        'shortBreakDuration': 5,
        'longBreakDuration': 15,
        'soundEnabled': true,
        'notificationsEnabled': true,
        'darkMode': true,
      };
    }
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    await _prefs.setString(_settingsKey, jsonEncode(settings));
  }
}
