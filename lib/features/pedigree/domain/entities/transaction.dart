class Transaction {
  final int id;
  final String transactionType;
  final String category;
  final double amount;
  final DateTime date;
  final String? notes;
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.transactionType,
    required this.category,
    required this.amount,
    required this.date,
    this.notes,
    required this.createdAt,
  });
}
