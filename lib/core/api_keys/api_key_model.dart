class ApiKeyEntry {
  final String id;
  final String name;
  final String key;
  final String? description;
  final String emoji;

  const ApiKeyEntry({
    required this.id,
    required this.name,
    required this.key,
    this.description,
    this.emoji = '🔑',
  });

  ApiKeyEntry copyWith({String? name, String? key, String? description, String? emoji}) => ApiKeyEntry(
    id: id, name: name ?? this.name, key: key ?? this.key,
    description: description ?? this.description, emoji: emoji ?? this.emoji,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'key': key,
    'description': description, 'emoji': emoji,
  };

  factory ApiKeyEntry.fromJson(Map<String, dynamic> j) => ApiKeyEntry(
    id:          j['id'] as String,
    name:        j['name'] as String,
    key:         j['key'] as String,
    description: j['description'] as String?,
    emoji:       j['emoji'] as String? ?? '🔑',
  );
}
