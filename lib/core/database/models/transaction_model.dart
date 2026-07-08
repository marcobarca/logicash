class TransactionModel {
  final String id;
  final String date;
  final String yearMonth;
  final String? operation;
  final String? details;
  final String? account;
  final String? category;
  final String currency;
  final double amount;

  const TransactionModel({
    required this.id,
    required this.date,
    required this.yearMonth,
    this.operation,
    this.details,
    this.account,
    this.category,
    this.currency = 'EUR',
    required this.amount,
  });

  bool get isExpense => amount < 0;
  bool get isIncome => amount > 0;
  double get absAmount => amount.abs();

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date,
        'year_month': yearMonth,
        'operation': operation,
        'details': details,
        'account': account,
        'category': category,
        'currency': currency,
        'amount': amount,
      };

  factory TransactionModel.fromMap(Map<String, dynamic> map) => TransactionModel(
        id: map['id'] as String,
        date: map['date'] as String,
        yearMonth: map['year_month'] as String,
        operation: map['operation'] as String?,
        details: map['details'] as String?,
        account: map['account'] as String?,
        category: map['category'] as String?,
        currency: map['currency'] as String? ?? 'EUR',
        amount: (map['amount'] as num).toDouble(),
      );
}
