enum SubscriptionFrequency { weekly, monthly, yearly, unknown }

class SubscriptionModel {
  final int? id;
  final String name;
  final double amount;
  final SubscriptionFrequency frequency;
  final bool confirmedByUser;
  final String? category;
  final String lastSeen;

  const SubscriptionModel({
    this.id,
    required this.name,
    required this.amount,
    required this.frequency,
    this.confirmedByUser = false,
    this.category,
    required this.lastSeen,
  });

  double get monthlyAmount {
    switch (frequency) {
      case SubscriptionFrequency.weekly:
        return amount * 4.33;
      case SubscriptionFrequency.monthly:
        return amount;
      case SubscriptionFrequency.yearly:
        return amount / 12;
      case SubscriptionFrequency.unknown:
        return amount;
    }
  }

  double get yearlyAmount => monthlyAmount * 12;

  String get frequencyLabel {
    switch (frequency) {
      case SubscriptionFrequency.weekly:
        return 'Settimanale';
      case SubscriptionFrequency.monthly:
        return 'Mensile';
      case SubscriptionFrequency.yearly:
        return 'Annuale';
      case SubscriptionFrequency.unknown:
        return 'Ricorrente';
    }
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'amount': amount,
        'frequency': frequency.index,
        'confirmed_by_user': confirmedByUser ? 1 : 0,
        'category': category,
        'last_seen': lastSeen,
      };

  factory SubscriptionModel.fromMap(Map<String, dynamic> map) => SubscriptionModel(
        id: map['id'] as int?,
        name: map['name'] as String,
        amount: (map['amount'] as num).toDouble(),
        frequency: SubscriptionFrequency.values[map['frequency'] as int],
        confirmedByUser: (map['confirmed_by_user'] as int) == 1,
        category: map['category'] as String?,
        lastSeen: map['last_seen'] as String,
      );
}
