class AccountModel {
  final int? id;
  final String name;
  final double balance;
  final String emoji;

  const AccountModel({
    this.id,
    required this.name,
    required this.balance,
    this.emoji = '🏦',
  });

  AccountModel copyWith({int? id, String? name, double? balance, String? emoji}) {
    return AccountModel(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      emoji: emoji ?? this.emoji,
    );
  }

  Map<String, dynamic> toMap() => {'name': name, 'balance': balance, 'emoji': emoji};

  factory AccountModel.fromMap(Map<String, dynamic> m) => AccountModel(
        id: m['id'] as int?,
        name: m['name'] as String,
        balance: m['balance'] as double,
        emoji: (m['emoji'] as String?) ?? '🏦',
      );
}
