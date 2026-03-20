import 'package:flutter/material.dart';
import '../models/transaction_model.dart';

class ExpenseService extends ChangeNotifier {
  List<TransactionModel> _transactions = [];

  // Getter trả về danh sách (có thể lọc nếu cần)
  List<TransactionModel> get transactions => _transactions;

  Future<void> initialize() async {
    // Giả lập dữ liệu ban đầu
    _transactions = [
      TransactionModel(id: '1', title: 'Ăn trưa', amount: 50000, date: DateTime.now(), type: TransactionType.expense, category: 'Food'),
      TransactionModel(id: '2', title: 'Tiền lương', amount: 10000000, date: DateTime.now(), type: TransactionType.income, category: 'Salary'),
      TransactionModel(id: '3', title: 'Mua sách', amount: 150000, date: DateTime.now().subtract(const Duration(days: 1)), type: TransactionType.expense, category: 'Education'),
    ];
    notifyListeners();
  }

  void addTransaction(TransactionModel transaction) {
    _transactions.add(transaction);
    notifyListeners();
  }

  void deleteTransaction(String id) {
    _transactions.removeWhere((t) => t.id == id);
    notifyListeners();
  }
  
  // Hàm hỗ trợ Undo: Thêm lại vào vị trí cũ hoặc thêm mới
  void undoDelete(TransactionModel transaction) {
    _transactions.add(transaction);
    // Sắp xếp lại theo ngày giảm dần để UI hiển thị đúng
    _transactions.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  void editTransaction(TransactionModel updatedTransaction) {
    final index = _transactions.indexWhere((t) => t.id == updatedTransaction.id);
    if (index != -1) {
      _transactions[index] = updatedTransaction;
      notifyListeners();
    }
  }

  // Logic tìm kiếm
  List<TransactionModel> searchTransactions(String query) {
    if (query.isEmpty) return _transactions;
    return _transactions.where((t) {
      return t.title.toLowerCase().contains(query.toLowerCase()) ||
             t.category.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }
}