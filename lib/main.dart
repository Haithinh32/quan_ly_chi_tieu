import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/dashboard_screen.dart';
import 'services/expense_service.dart';

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
      title: 'Quản lý Tài chính',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}
