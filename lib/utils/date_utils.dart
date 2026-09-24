import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StudyDateUtils {
  static final DateFormat timeFormat = DateFormat('hh:mm a');
  static final DateFormat dateFormat = DateFormat('MMM dd, yyyy');
  static final DateFormat shortDateFormat = DateFormat('EEE, MMM d');
  static final DateFormat fullDateTimeFormat = DateFormat('MMM dd, yyyy hh:mm a');

  static String formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return timeFormat.format(dt);
  }

  static String formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes mins';
    }
    final hours = minutes ~/ 60;
    final remainingMins = minutes % 60;
    if (remainingMins == 0) {
      return '$hours hrs';
    }
    return '${hours}h ${remainingMins}m';
  }

  static String formatSeconds(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  static String getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }

  static String formatDaysOfWeek(List<int> days) {
    if (days.length == 7) return 'Everyday';
    if (days.length == 5 &&
        days.contains(1) &&
        days.contains(2) &&
        days.contains(3) &&
        days.contains(4) &&
        days.contains(5)) {
      return 'Weekdays (Mon-Fri)';
    }
    if (days.length == 2 && days.contains(6) && days.contains(7)) {
      return 'Weekends (Sat-Sun)';
    }
    final sorted = List<int>.from(days)..sort();
    return sorted.map((d) => getDayName(d)).join(', ');
  }
}
