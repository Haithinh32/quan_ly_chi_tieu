import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/expense_service.dart';
import '../models/transaction.dart';
import '../models/category.dart';

class TransactionFormScreen extends StatefulWidget {
  final Map<String, dynamic>? existingTransaction;

  const TransactionFormScreen({Key? key, this.existingTransaction}) : super(key: key);

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers lấy dữ liệu từ các ô nhập
  final _amountController = TextEditingController();
  final _noteController = TextEditingController(); // Đây là Tiêu đề/Ghi chú của giao dịch
  
  DateTime _selectedDate = DateTime.now();
  String _type = 'expense'; // 'expense' hoặc 'income'
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Nếu là chế độ Sửa, đổ dữ liệu cũ vào Form
    if (widget.existingTransaction != null) {
      _amountController.text = widget.existingTransaction!['amount']?.toString() ?? '';
      _noteController.text = widget.existingTransaction!['note'] ?? '';
      _type = widget.existingTransaction!['type'] ?? 'expense';
      _selectedDate = widget.existingTransaction!['date'] ?? DateTime.now();
    }
  }

  // Hàm hiển thị lịch chọn ngày
  void _presentDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() => _selectedDate = pickedDate);
    }
  }

  // Hàm xử lý Lưu dữ liệu vào ExpenseService của nhóm
  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    // Giả lập hiệu ứng Loading cho mượt
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    try {
      final expenseService = Provider.of<ExpenseService>(context, listen: false);

      // Tạo Object Transaction đúng chuẩn Model của nhóm bạn
      final transaction = Transaction(
        id: widget.existingTransaction?['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        categoryId: '1', // Tạm để ID '1' (Ăn uống) cho đến khi tích hợp nốt phần 4
        amount: double.parse(_amountController.text),
        note: _noteController.text, // Nhóm dùng trường note làm nội dung hiển thị
        date: _selectedDate,
        type: _type == 'expense' ? CategoryType.expense : CategoryType.income,
      );

      // Gọi hàm từ ExpenseService đã có sẵn của nhóm
      if (widget.existingTransaction == null) {
        expenseService.addTransaction(transaction);
      } else {
        expenseService.updateTransaction(transaction);
      }

      // Thông báo thành công
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_type == 'expense' ? 'Đã lưu khoản chi ✅' : 'Đã lưu khoản thu ✅'),
          backgroundColor: _type == 'expense' ? Colors.redAccent : Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      Navigator.of(context).pop(); // Quay lại Dashboard
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _type == 'expense' ? Colors.redAccent : Colors.green;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingTransaction == null ? 'Thêm giao dịch' : 'Sửa giao dịch'),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Toggle Thu/Chi
                  _buildTypeToggle(themeColor),
                  const SizedBox(height: 25),

                  // 2. Nhập số tiền
                  TextFormField(
                    controller: _amountController,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Số tiền',
                      suffixText: 'VNĐ',
                      prefixIcon: const Icon(Icons.money),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (val) => (val == null || double.tryParse(val) == null) ? 'Vui lòng nhập số tiền hợp lệ' : null,
                  ),
                  const SizedBox(height: 20),

                  // 3. Nhập tiêu đề/ghi chú
                  TextFormField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      labelText: 'Tiêu đề / Ghi chú',
                      hintText: 'Ăn sáng, Lương, Mua đồ...',
                      prefixIcon: const Icon(Icons.edit),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) => (val == null || val.isEmpty) ? 'Vui lòng nhập nội dung' : null,
                  ),
                  const SizedBox(height: 20),

                  // 4. Chọn ngày
                  InkWell(
                    onTap: _presentDatePicker,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Ngày giao dịch',
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                    ),
                  ),
                  const SizedBox(height: 35),

                  // 5. Nút Lưu
                  SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _submitData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'LƯU GIAO DỊCH', 
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildTypeToggle(Color themeColor) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          _buildToggleItem('expense', 'Chi tiêu', Colors.redAccent),
          _buildToggleItem('income', 'Thu nhập', Colors.green),
        ],
      ),
    );
  }

  Widget _buildToggleItem(String type, String label, Color color) {
    bool isSelected = _type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label, 
              style: TextStyle(color: isSelected ? Colors.white : Colors.black54, fontWeight: FontWeight.bold)
            ),
          ),
        ),
      ),
    );
  }
}