class ChecklistItem {
  final String id;
  String text;
  bool isDone;

  ChecklistItem({
    required this.id,
    required this.text,
    this.isDone = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'isDone': isDone,
      };

  factory ChecklistItem.fromJson(Map<String, dynamic> json) => ChecklistItem(
        id: json['id'] as String,
        text: json['text'] as String? ?? '',
        isDone: json['isDone'] as bool? ?? false,
      );

  ChecklistItem copyWith({
    String? id,
    String? text,
    bool? isDone,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      text: text ?? this.text,
      isDone: isDone ?? this.isDone,
    );
  }
}

class StudyNote {
  final String id;
  final String? scheduleId;
  final String? sessionId;
  final String subjectId;
  final String title;
  final String contentMarkdown;
  final List<ChecklistItem> checklist;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  StudyNote({
    required this.id,
    this.scheduleId,
    this.sessionId,
    required this.subjectId,
    required this.title,
    required this.contentMarkdown,
    this.checklist = const [],
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'scheduleId': scheduleId,
        'sessionId': sessionId,
        'subjectId': subjectId,
        'title': title,
        'contentMarkdown': contentMarkdown,
        'checklist': checklist.map((i) => i.toJson()).toList(),
        'tags': tags,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory StudyNote.fromJson(Map<String, dynamic> json) => StudyNote(
        id: json['id'] as String,
        scheduleId: json['scheduleId'] as String?,
        sessionId: json['sessionId'] as String?,
        subjectId: json['subjectId'] as String,
        title: json['title'] as String,
        contentMarkdown: json['contentMarkdown'] as String? ?? '',
        checklist: (json['checklist'] as List<dynamic>?)
                ?.map((i) => ChecklistItem.fromJson(i as Map<String, dynamic>))
                .toList() ??
            [],
        tags: (json['tags'] as List<dynamic>?)?.map((t) => t.toString()).toList() ??
            [],
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  StudyNote copyWith({
    String? id,
    String? scheduleId,
    String? sessionId,
    String? subjectId,
    String? title,
    String? contentMarkdown,
    List<ChecklistItem>? checklist,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudyNote(
      id: id ?? this.id,
      scheduleId: scheduleId ?? this.scheduleId,
      sessionId: sessionId ?? this.sessionId,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      contentMarkdown: contentMarkdown ?? this.contentMarkdown,
      checklist: checklist ?? this.checklist,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
