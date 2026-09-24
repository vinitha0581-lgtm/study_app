import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/study_schedule.dart';
import '../models/subject.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

class ScheduleProvider with ChangeNotifier {
  final StorageService _storageService;
  final NotificationService _notificationService = NotificationService();
  final _uuid = const Uuid();

  List<StudySchedule> _schedules = [];
  List<Subject> _subjects = [];

  ScheduleProvider(this._storageService) {
    loadData();
  }

  List<StudySchedule> get schedules => _schedules;
  List<Subject> get subjects => _subjects;

  List<StudySchedule> get todaySchedules {
    final today = DateTime.now().weekday;
    final list = _schedules.where((s) => s.daysOfWeek.contains(today)).toList();
    list.sort((a, b) {
      final aMin = a.startTime.hour * 60 + a.startTime.minute;
      final bMin = b.startTime.hour * 60 + b.startTime.minute;
      return aMin.compareTo(bMin);
    });
    return list;
  }

  StudySchedule? get nextUpcomingScheduleToday {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    for (final schedule in todaySchedules) {
      final startMin = schedule.startTime.hour * 60 + schedule.startTime.minute;
      final endMin = schedule.endTime.hour * 60 + schedule.endTime.minute;
      if (endMin > currentMinutes && schedule.isEnabled) {
        return schedule;
      }
    }
    return null;
  }

  void loadData() {
    _schedules = _storageService.getSchedules();
    _subjects = _storageService.getSubjects();
    _rescheduleAllNotifications();
    notifyListeners();
  }

  Subject? getSubjectById(String subjectId) {
    try {
      return _subjects.firstWhere((s) => s.id == subjectId);
    } catch (_) {
      return null;
    }
  }

  Future<void> addSchedule({
    required String subjectId,
    required String title,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required List<int> daysOfWeek,
    int reminderMinutesBefore = 10,
    String description = '',
  }) async {
    final schedule = StudySchedule(
      id: _uuid.v4(),
      subjectId: subjectId,
      title: title,
      startTime: startTime,
      endTime: endTime,
      daysOfWeek: daysOfWeek,
      reminderMinutesBefore: reminderMinutesBefore,
      description: description,
      isEnabled: true,
    );
    _schedules.add(schedule);
    await _storageService.saveSchedules(_schedules);
    await _notificationService.scheduleStudyNotification(schedule);
    notifyListeners();
  }

  Future<void> updateSchedule(StudySchedule updated) async {
    final index = _schedules.indexWhere((s) => s.id == updated.id);
    if (index != -1) {
      await _notificationService.cancelScheduleNotifications(_schedules[index]);
      _schedules[index] = updated;
      await _storageService.saveSchedules(_schedules);
      if (updated.isEnabled) {
        await _notificationService.scheduleStudyNotification(updated);
      }
      notifyListeners();
    }
  }

  Future<void> toggleSchedule(String scheduleId) async {
    final index = _schedules.indexWhere((s) => s.id == scheduleId);
    if (index != -1) {
      final current = _schedules[index];
      final toggled = current.copyWith(isEnabled: !current.isEnabled);
      _schedules[index] = toggled;
      await _storageService.saveSchedules(_schedules);
      if (toggled.isEnabled) {
        await _notificationService.scheduleStudyNotification(toggled);
      } else {
        await _notificationService.cancelScheduleNotifications(toggled);
      }
      notifyListeners();
    }
  }

  Future<void> deleteSchedule(String scheduleId) async {
    final schedule = _schedules.firstWhere((s) => s.id == scheduleId);
    await _notificationService.cancelScheduleNotifications(schedule);
    _schedules.removeWhere((s) => s.id == scheduleId);
    await _storageService.saveSchedules(_schedules);
    notifyListeners();
  }

  Future<void> addSubject(String name, int colorValue, {String icon = 'book', int targetMinutes = 300}) async {
    final subject = Subject(
      id: _uuid.v4(),
      name: name,
      colorValue: colorValue,
      iconName: icon,
      targetMinutesPerWeek: targetMinutes,
    );
    _subjects.add(subject);
    await _storageService.saveSubjects(_subjects);
    notifyListeners();
  }

  Future<void> _rescheduleAllNotifications() async {
    for (final sch in _schedules) {
      if (sch.isEnabled) {
        await _notificationService.scheduleStudyNotification(sch);
      }
    }
  }
}
