import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/expense_service.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import 'transaction_form_screen.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({Key? key}) : super(key: key);

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Hàm xử lý mở màn hình Sửa
  void _editTransaction(BuildContext context, Transaction transaction) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionFormScreen(
          existingTransaction: {
            'id': transaction.id,
            'amount': transaction.amount,
            'note': transaction.note,
            'date': transaction.date,
            'type': transaction.type == CategoryType.income ? 'income' : 'expense',
          },
        ),
      ),
    );
  }

  // Hàm xử lý Xóa và Undo
  void _deleteTransaction(BuildContext context, ExpenseService service, Transaction transaction) {
    service.deleteTransaction(transaction.id);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Đã xóa giao dịch'),
        action: SnackBarAction(
          label: 'HOÀN TÁC',
          onPressed: () {
            service.addTransaction(transaction);
          },
        ),
      ),
    );
  }

  // Nhóm giao dịch theo ngày
  Map<String, List<Transaction>> _groupTransactionsByDate(List<Transaction> transactions) {
    final Map<String, List<Transaction>> grouped = {};
    
    for (var transaction in transactions) {
      // Bỏ qua nếu không khớp tìm kiếm
      if (_searchQuery.isNotEmpty) {
        final note = transaction.note.toLowerCase();
        final amount = transaction.amount.toString();
        if (!note.contains(_searchQuery.toLowerCase()) && !amount.contains(_searchQuery)) {
          continue;
        }
      }

      // Tạo key ngày tháng (dd/MM/yyyy)
      final dateKey = DateFormat('dd/MM/yyyy').format(transaction.date);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(transaction);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<ExpenseService>(context);
    final groupedTransactions = _groupTransactionsByDate(service.transactions);
    final sortedKeys = groupedTransactions.keys.toList()
      ..sort((a, b) => DateFormat('dd/MM/yyyy').parse(b).compareTo(DateFormat('dd/MM/yyyy').parse(a)));

    return Scaffold(
      appBar: AppBar(
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: const InputDecoration(
              hintText: 'Tìm kiếm giao dịch...',
              prefixIcon: Icon(Icons.search, color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
      ),
      body: sortedKeys.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isEmpty ? 'Chưa có giao dịch nào' : 'Không tìm thấy kết quả',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: sortedKeys.length,
              itemBuilder: (context, index) {
                final dateKey = sortedKeys[index];
                final transactions = groupedTransactions[dateKey]!;
                return _buildDateGroup(context, service, dateKey, transactions);
              },
            ),
    );
  }

  Widget _buildDateGroup(BuildContext context, ExpenseService service, String date, List<Transaction> transactions) {
    // Tính tổng thu chi trong ngày (Optional UI enhancement)
    double dailyTotal = 0;
    for (var t in transactions) {
      dailyTotal += (t.type == CategoryType.income ? t.amount : -t.amount);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.grey.shade100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDateTitle(date),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
              ),
              Text(
                dailyTotal > 0 ? '+${_currencyFormat.format(dailyTotal)}' : _currencyFormat.format(dailyTotal),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: dailyTotal >= 0 ? Colors.black54 : Colors.red.shade300,
                ),
              )
            ],
          ),
        ),
        ...transactions.map((t) => _buildTransactionItem(context, service, t)).toList(),
      ],
    );
  }

  String _formatDateTitle(String dateStr) {
    final date = DateFormat('dd/MM/yyyy').parse(dateStr);
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Hôm nay ($dateStr)';
    } else if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
      return 'Hôm qua ($dateStr)';
    }
    return _getDayOfWeek(date) + ', ' + dateStr;
  }

  String _getDayOfWeek(DateTime date) {
    const days = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'CN'];
    return days[date.weekday - 1];
  }

  Widget _buildTransactionItem(BuildContext context, ExpenseService service, Transaction t) {
    final category = service.getCategoryById(t.categoryId);
    final isIncome = t.type == CategoryType.income;

    return Dismissible(
      key: Key(t.id),
      // Vuốt phải để Sửa
      background: Container(
        color: Colors.blue,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      // Vuốt trái để Xóa
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Hướng Sửa -> Không dismiss item, chỉ chuyển màn hình
          _editTransaction(context, t);
          return false; 
        } else {
          // Hướng Xóa -> Cho phép dismiss
          return true;
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          _deleteTransaction(context, service, t);
        }
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: category.color.withOpacity(0.1),
          child: Icon(category.icon, color: category.color),
        ),
        title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: t.note.isNotEmpty 
            ? Text(t.note, maxLines: 1, overflow: TextOverflow.ellipsis) 
            : null,
        trailing: Text(
          '${isIncome ? '+' : '-'}${_currencyFormat.format(t.amount)}',
          style: TextStyle(
            color: isIncome ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}