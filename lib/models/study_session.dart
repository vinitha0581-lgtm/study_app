enum SessionType { pomodoro, custom, scheduled }

class StudySession {
  final String id;
  final String? scheduleId;
  final String subjectId;
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
  final SessionType type;
  final bool isCompleted;
  final String? noteId;

  StudySession({
    required this.id,
    this.scheduleId,
    required this.subjectId,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    this.type = SessionType.custom,
    this.isCompleted = true,
    this.noteId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'scheduleId': scheduleId,
        'subjectId': subjectId,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'durationMinutes': durationMinutes,
        'type': type.name,
        'isCompleted': isCompleted,
        'noteId': noteId,
      };

  factory StudySession.fromJson(Map<String, dynamic> json) => StudySession(
        id: json['id'] as String,
        scheduleId: json['scheduleId'] as String?,
        subjectId: json['subjectId'] as String,
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: DateTime.parse(json['endTime'] as String),
        durationMinutes: json['durationMinutes'] as int? ?? 0,
        type: SessionType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => SessionType.custom,
        ),
        isCompleted: json['isCompleted'] as bool? ?? true,
        noteId: json['noteId'] as String?,
      );
}
