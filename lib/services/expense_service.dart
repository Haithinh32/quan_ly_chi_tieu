import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/category.dart'; // Import để dùng CategoryType

class ExpenseService extends ChangeNotifier {
  List<Transaction> _transactions = [];

  // Getter trả về danh sách (có thể lọc nếu cần)
  List<Transaction> get transactions => _transactions;

  Future<void> initialize() async {
    // Giả lập dữ liệu ban đầu
    _transactions = [
      Transaction(amount: 50000, note: 'Ăn trưa', date: DateTime.now(), type: CategoryType.expense, categoryId: 'Food'),
      Transaction(amount: 10000000, note: 'Tiền lương', date: DateTime.now(), type: CategoryType.income, categoryId: 'Salary'),
      Transaction(amount: 150000, note: 'Mua sách', date: DateTime.now().subtract(const Duration(days: 1)), type: CategoryType.expense, categoryId: 'Education'),
    ];
    notifyListeners();
  }

  void addTransaction(Transaction transaction) {
    _transactions.add(transaction);
    notifyListeners();
  }

  void deleteTransaction(String id) {
    _transactions.removeWhere((t) => t.id == id);
    notifyListeners();
  }
  
  // Hàm hỗ trợ Undo: Thêm lại vào vị trí cũ hoặc thêm mới
  void undoDelete(Transaction transaction) {
    _transactions.add(transaction);
    // Sắp xếp lại theo ngày giảm dần để UI hiển thị đúng
    _transactions.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  void editTransaction(Transaction updatedTransaction) {
    final index = _transactions.indexWhere((t) => t.id == updatedTransaction.id);
    if (index != -1) {
      _transactions[index] = updatedTransaction;
      notifyListeners();
    }
  }

  // Logic tìm kiếm
  List<Transaction> searchTransactions(String query) {
    if (query.isEmpty) return _transactions;
    return _transactions.where((t) {
      // Tìm theo Note hoặc CategoryId
      return t.note.toLowerCase().contains(query.toLowerCase()) ||
             t.categoryId.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }
}