import 'package:uuid/uuid.dart';
import 'category.dart';

class Transaction {
  final String id;
  final double amount;
  final String note;
  final DateTime date;
  final String categoryId;
  final CategoryType type;

  Transaction({
    String? id,
    required this.amount,
    required this.note,
    required this.date,
    required this.categoryId,
    required this.type,
  }) : id = id ?? const Uuid().v4();

  Transaction copyWith({
    double? amount,
    String? note,
    DateTime? date,
    String? categoryId,
    CategoryType? type,
  }) {
    return Transaction(
      id: id,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
    );
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'note': note,
      'date': date.toIso8601String(),
      'categoryId': categoryId,
      'type': type.index,
    };
  }

  // Create from JSON
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      note: json['note'] as String,
      date: DateTime.parse(json['date'] as String),
      categoryId: json['categoryId'] as String,
      type: CategoryType.values[json['type'] as int],
    );
  }
}
