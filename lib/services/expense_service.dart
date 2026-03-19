import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/transaction.dart';
import '../models/category.dart';

class ExpenseService with ChangeNotifier {
  late SharedPreferences _prefs;
  final List<Transaction> _transactions = [];
  final List<Category> _categories = [];
  
  static const String _transactionsKey = 'transactions';
  static const String _categoriesKey = 'categories';
  static const String _initKey = 'initialized';

  bool get isInitialized => _prefs.getBool(_initKey) ?? false;

  final List<Category> _defaultCategories = [
    Category(id: '1', name: 'Ăn uống', icon: Icons.restaurant, color: Colors.orange, type: CategoryType.expense),
    Category(id: '2', name: 'Di chuyển', icon: Icons.directions_bus, color: Colors.blue, type: CategoryType.expense),
    Category(id: '3', name: 'Lương', icon: Icons.attach_money, color: Colors.green, type: CategoryType.income),
    Category(id: '4', name: 'Mua sắm', icon: Icons.shopping_bag, color: Colors.pink, type: CategoryType.expense),
    Category(id: '5', name: 'Giải trí', icon: Icons.movie, color: Colors.purple, type: CategoryType.expense),
  ];

  List<Transaction> get transactions => List.unmodifiable(_transactions..sort((a, b) => b.date.compareTo(a.date)));
  List<Category> get categories => List.unmodifiable(_categories);

  double get totalIncome => _transactions
      .where((t) => t.type == CategoryType.income)
      .fold(0, (sum, t) => sum + t.amount);

  double get totalExpense => _transactions
      .where((t) => t.type == CategoryType.expense)
      .fold(0, (sum, t) => sum + t.amount);

  double get balance => totalIncome - totalExpense;

  // Initialize the service and load data from SharedPreferences
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadCategories();
    await _loadTransactions();
  }

  // Load transactions from SharedPreferences
  Future<void> _loadTransactions() async {
    try {
      final transactionsJson = _prefs.getString(_transactionsKey);
      if (transactionsJson != null && transactionsJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(transactionsJson);
        _transactions.clear();
        _transactions.addAll(
          decoded.map((item) => Transaction.fromJson(item as Map<String, dynamic>)).toList(),
        );
      }
    } catch (e) {
      debugPrint('Error loading transactions: $e');
    }
  }

  // Load categories from SharedPreferences
  Future<void> _loadCategories() async {
    try {
      final categoriesJson = _prefs.getString(_categoriesKey);
      if (categoriesJson != null && categoriesJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(categoriesJson);
        _categories.clear();
        _categories.addAll(
          decoded.map((item) => Category.fromJson(item as Map<String, dynamic>)).toList(),
        );
      } else {
        // First time: use default categories
        _categories.addAll(_defaultCategories);
        await _saveCategories();
      }
    } catch (e) {
      debugPrint('Error loading categories: $e');
      _categories.addAll(_defaultCategories);
      await _saveCategories();
    }
  }

  // Save transactions to SharedPreferences
  Future<void> _saveTransactions() async {
    try {
      final jsonList = _transactions.map((t) => t.toJson()).toList();
      await _prefs.setString(_transactionsKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving transactions: $e');
    }
  }

  // Save categories to SharedPreferences
  Future<void> _saveCategories() async {
    try {
      final jsonList = _categories.map((c) => c.toJson()).toList();
      await _prefs.setString(_categoriesKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving categories: $e');
    }
  }

  void addTransaction(Transaction transaction) {
    _transactions.add(transaction);
    _saveTransactions();
    notifyListeners();
  }

  void updateTransaction(Transaction transaction) {
    final index = _transactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      _transactions[index] = transaction;
      _saveTransactions();
      notifyListeners();
    }
  }

  void deleteTransaction(String id) {
    _transactions.removeWhere((t) => t.id == id);
    _saveTransactions();
    notifyListeners();
  }

  Category getCategoryById(String id) {
    return _categories.firstWhere(
      (c) => c.id == id,
      orElse: () => Category(id: '0', name: 'Khác', icon: Icons.help_outline, color: Colors.grey, type: CategoryType.expense),
    );
  }

  void addCategory(Category category) {
    _categories.add(category);
    _saveCategories();
    notifyListeners();
  }

  void updateCategory(Category category) {
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      _categories[index] = category;
      _saveCategories();
      notifyListeners();
    }
  }

  void deleteCategory(String id) {
    _categories.removeWhere((c) => c.id == id);
    _saveCategories();
    notifyListeners();
  }

  // Clear all data
  Future<void> clearAllData() async {
    _transactions.clear();
    _categories.clear();
    _categories.addAll(_defaultCategories);
    await _prefs.clear();
    await _saveCategories();
    notifyListeners();
  }
}
