class ExpenseModel {
  final String id;
  final String
  title; // Was 'category' in request, but title is useful. Request said 'Category' overview. Let's strictly follow request: Amount, Category, Date. I'll add Title/Note as well for list display.
  final double amount;
  final String category;
  final DateTime date;
  final String? note;

  ExpenseModel({
    required this.id,
    this.title = 'Expense',
    required this.amount,
    required this.category,
    required this.date,
    this.note,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  // Create from JSON
  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'],
      title: json['title'],
      amount: json['amount'],
      category: json['category'],
      date: DateTime.parse(json['date']),
      note: json['note'],
    );
  }
}
