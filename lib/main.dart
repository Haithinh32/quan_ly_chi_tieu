import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/main_shell.dart';
import 'services/expense_service.dart';
import 'screens/transaction_list_screen.dart'; // Import màn hình mới

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final expenseService = ExpenseService();
  await expenseService.initialize();
  
  runApp(
    ChangeNotifierProvider(
      create: (context) => expenseService,
      child: const ExpenseTrackerApp(),
    ),
  );
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker - G15_C3',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      home: const TransactionListScreen(), // Đổi tạm để test màn hình danh sách
    );
  }
}
