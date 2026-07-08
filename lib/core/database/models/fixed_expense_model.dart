enum FixedExpenseFrequency { weekly, monthly, yearly }

class FixedExpenseModel {
  final int? id;
  final String name;
  final double amount;
  final FixedExpenseFrequency frequency;
  final String? category;
  final String? emoji;
  final bool confirmedByUser;
  final bool isManual;

  const FixedExpenseModel({
    this.id,
    required this.name,
    required this.amount,
    required this.frequency,
    this.category,
    this.emoji,
    this.confirmedByUser = false,
    this.isManual = false,
  });

  double get monthlyAmount {
    switch (frequency) {
      case FixedExpenseFrequency.weekly:  return amount * 4.33;
      case FixedExpenseFrequency.monthly: return amount;
      case FixedExpenseFrequency.yearly:  return amount / 12;
    }
  }

  double get yearlyAmount => monthlyAmount * 12;

  String get frequencyLabel {
    switch (frequency) {
      case FixedExpenseFrequency.weekly:  return 'Settimanale';
      case FixedExpenseFrequency.monthly: return 'Mensile';
      case FixedExpenseFrequency.yearly:  return 'Annuale';
    }
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'amount': amount,
        'frequency': frequency.index,
        'category': category,
        'emoji': emoji,
        'confirmed_by_user': confirmedByUser ? 1 : 0,
        'is_manual': isManual ? 1 : 0,
      };

  factory FixedExpenseModel.fromMap(Map<String, dynamic> map) => FixedExpenseModel(
        id: map['id'] as int?,
        name: map['name'] as String,
        amount: (map['amount'] as num).toDouble(),
        frequency: FixedExpenseFrequency.values[map['frequency'] as int],
        category: map['category'] as String?,
        emoji: map['emoji'] as String?,
        confirmedByUser: (map['confirmed_by_user'] as int? ?? 0) == 1,
        isManual: (map['is_manual'] as int? ?? 0) == 1,
      );

  FixedExpenseModel copyWith({
    int? id, String? name, double? amount, FixedExpenseFrequency? frequency,
    String? category, String? emoji, bool? confirmedByUser, bool? isManual,
  }) => FixedExpenseModel(
        id: id ?? this.id,
        name: name ?? this.name,
        amount: amount ?? this.amount,
        frequency: frequency ?? this.frequency,
        category: category ?? this.category,
        emoji: emoji ?? this.emoji,
        confirmedByUser: confirmedByUser ?? this.confirmedByUser,
        isManual: isManual ?? this.isManual,
      );
}
