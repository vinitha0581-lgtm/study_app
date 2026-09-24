import 'package:flutter/material.dart';

class StudySchedule {
  final String id;
  final String subjectId;
  final String title;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final List<int> daysOfWeek; // 1 = Monday, 7 = Sunday (DateTime.monday .. sunday)
  final int reminderMinutesBefore; // e.g. 10 mins before
  final bool isEnabled;
  final String description;

  StudySchedule({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.daysOfWeek,
    this.reminderMinutesBefore = 10,
    this.isEnabled = true,
    this.description = '',
  });

  int get durationMinutes {
    final startTotal = startTime.hour * 60 + startTime.minute;
    var endTotal = endTime.hour * 60 + endTime.minute;
    if (endTotal <= startTotal) {
      endTotal += 24 * 60; // handles overnight study
    }
    return endTotal - startTotal;
  }

  bool isScheduledForToday() {
    final today = DateTime.now().weekday;
    return daysOfWeek.contains(today);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'subjectId': subjectId,
        'title': title,
        'startHour': startTime.hour,
        'startMinute': startTime.minute,
        'endHour': endTime.hour,
        'endMinute': endTime.minute,
        'daysOfWeek': daysOfWeek,
        'reminderMinutesBefore': reminderMinutesBefore,
        'isEnabled': isEnabled,
        'description': description,
      };

  factory StudySchedule.fromJson(Map<String, dynamic> json) => StudySchedule(
        id: json['id'] as String,
        subjectId: json['subjectId'] as String,
        title: json['title'] as String,
        startTime: TimeOfDay(
          hour: json['startHour'] as int? ?? 9,
          minute: json['startMinute'] as int? ?? 0,
        ),
        endTime: TimeOfDay(
          hour: json['endHour'] as int? ?? 10,
          minute: json['endMinute'] as int? ?? 0,
        ),
        daysOfWeek: (json['daysOfWeek'] as List<dynamic>?)
                ?.map((e) => e as int)
                .toList() ??
            [1, 2, 3, 4, 5],
        reminderMinutesBefore: json['reminderMinutesBefore'] as int? ?? 10,
        isEnabled: json['isEnabled'] as bool? ?? true,
        description: json['description'] as String? ?? '',
      );

  StudySchedule copyWith({
    String? id,
    String? subjectId,
    String? title,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    List<int>? daysOfWeek,
    int? reminderMinutesBefore,
    bool? isEnabled,
    String? description,
  }) {
    return StudySchedule(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      reminderMinutesBefore:
          reminderMinutesBefore ?? this.reminderMinutesBefore,
      isEnabled: isEnabled ?? this.isEnabled,
      description: description ?? this.description,
    );
  }
}
