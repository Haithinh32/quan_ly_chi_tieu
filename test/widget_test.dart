import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

// Dùng đường dẫn tương đối để máy tự tìm file mà không cần tên package
import '../lib/main.dart';
import '../lib/services/expense_service.dart';

void main() {
  testWidgets('Kiểm tra ứng dụng có khởi chạy thành công hay không', (WidgetTester tester) async {
    // 1. Khởi tạo service
    final expenseService = ExpenseService();

    // 2. Xây dựng ứng dụng trong môi trường test
    await tester.pumpWidget(
      ChangeNotifierProvider<ExpenseService>(
        create: (context) => expenseService,
        child: const ExpenseTrackerApp(),
      ),
    );

    // 3. Kiểm tra xem ứng dụng có hiển thị đúng không
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}