class GoalModel {
  final int? id;
  final String name;
  final double target;
  final String createdAt;
  final String? emoji;

  const GoalModel({
    this.id,
    required this.name,
    required this.target,
    required this.createdAt,
    this.emoji,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'target': target,
        'created_at': createdAt,
        'emoji': emoji,
      };

  factory GoalModel.fromMap(Map<String, dynamic> map) => GoalModel(
        id: map['id'] as int?,
        name: map['name'] as String,
        target: (map['target'] as num).toDouble(),
        createdAt: map['created_at'] as String,
        emoji: map['emoji'] as String?,
      );

  GoalModel copyWith({int? id, String? name, double? target, String? createdAt, String? emoji}) =>
      GoalModel(
        id: id ?? this.id,
        name: name ?? this.name,
        target: target ?? this.target,
        createdAt: createdAt ?? this.createdAt,
        emoji: emoji ?? this.emoji,
      );
}
