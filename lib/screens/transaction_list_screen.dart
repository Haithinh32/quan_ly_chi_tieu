import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/expense_service.dart';
import '../models/transaction.dart';
import '../models/category.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Hàm nhóm các giao dịch theo ngày
  Map<String, List<Transaction>> _groupTransactionsByDate(List<Transaction> transactions) {
    Map<String, List<Transaction>> groups = {};
    for (var tx in transactions) {
      // Format ngày thành chuỗi để làm key (Ví dụ: "20/10/2023")
      String dateKey = DateFormat('dd/MM/yyyy').format(tx.date);
      if (!groups.containsKey(dateKey)) {
        groups[dateKey] = [];
      }
      groups[dateKey]!.add(tx);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử giao dịch'),
      ),
      body: Column(
        children: [
          // --- Thanh tìm kiếm ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm giao dịch...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // --- Danh sách giao dịch ---
          Expanded(
            child: Consumer<ExpenseService>(
              builder: (context, expenseService, child) {
                // 1. Lấy danh sách và lọc theo từ khóa
                final filteredList = expenseService.searchTransactions(_searchQuery);
                
                // 2. Sắp xếp theo ngày mới nhất
                filteredList.sort((a, b) => b.date.compareTo(a.date));

                // 3. Nhóm theo ngày
                final groupedTransactions = _groupTransactionsByDate(filteredList);
                final sortedKeys = groupedTransactions.keys.toList(); // List ngày đã format

                if (filteredList.isEmpty) {
                  return const Center(child: Text("Không có giao dịch nào"));
                }

                return ListView.builder(
                  itemCount: sortedKeys.length,
                  itemBuilder: (context, index) {
                    String dateKey = sortedKeys[index];
                    List<Transaction> transactionsOfDay = groupedTransactions[dateKey]!;
                    
                    // Tính tổng tiền trong ngày (Optional UI)
                    double totalDay = transactionsOfDay.fold(0, (sum, item) {
                      return item.type == CategoryType.income 
                          ? sum + item.amount 
                          : sum - item.amount;
                    });

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Ngày
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          color: Colors.grey[100],
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                dateKey,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                              ),
                              Text(
                                NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(totalDay),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        // Danh sách item trong ngày
                        ...transactionsOfDay.map((tx) => _buildTransactionItem(context, tx, expenseService)),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, Transaction tx, ExpenseService service) {
    final isIncome = tx.type == CategoryType.income;
    final color = isIncome ? Colors.green : Colors.red;
    final amountPrefix = isIncome ? '+' : '-';

    return Dismissible(
      key: Key(tx.id),
      // --- Vuốt Phải để Sửa (Background Xanh/Cam) ---
      background: Container(
        color: Colors.blue,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      // --- Vuốt Trái để Xóa (Background Đỏ) ---
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Hướng StartToEnd (Trái sang phải) -> Sửa
          // TODO: Điều hướng đến màn hình chỉnh sửa tại đây
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Chức năng sửa giao dịch '${tx.note}'")),
          );
          return false; // Trả về false để không xóa item khỏi list
        } else {
          // Hướng EndToStart (Phải sang trái) -> Xóa
          return true; // Trả về true để cho phép xóa
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          // Thực hiện xóa trong model
          service.deleteTransaction(tx.id);

          // Hiển thị Undo SnackBar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Đã xóa '${tx.note}'"),
              action: SnackBarAction(
                label: 'HOÀN TÁC',
                onPressed: () {
                  service.undoDelete(tx);
                },
              ),
            ),
          );
        }
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(
            isIncome ? Icons.arrow_downward : Icons.arrow_upward, // Income down (vào túi), Expense up (ra khỏi túi) hoặc icon tùy chọn
            color: color,
          ),
        ),
        title: Text(
          tx.note, // Dùng note làm tiêu đề chính
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(tx.categoryId), // Hiển thị tạm ID danh mục
        trailing: Text(
          '$amountPrefix${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(tx.amount)}',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}