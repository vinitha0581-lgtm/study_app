class Subject {
  final String id;
  final String name;
  final int colorValue;
  final String iconName;
  final int targetMinutesPerWeek;

  Subject({
    required this.id,
    required this.name,
    required this.colorValue,
    this.iconName = 'book',
    this.targetMinutesPerWeek = 300,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorValue': colorValue,
        'iconName': iconName,
        'targetMinutesPerWeek': targetMinutesPerWeek,
      };

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
        id: json['id'] as String,
        name: json['name'] as String,
        colorValue: json['colorValue'] as int? ?? 0xFF4F46E5,
        iconName: json['iconName'] as String? ?? 'book',
        targetMinutesPerWeek: json['targetMinutesPerWeek'] as int? ?? 300,
      );

  Subject copyWith({
    String? id,
    String? name,
    int? colorValue,
    String? iconName,
    int? targetMinutesPerWeek,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      iconName: iconName ?? this.iconName,
      targetMinutesPerWeek: targetMinutesPerWeek ?? this.targetMinutesPerWeek,
    );
  }
}
