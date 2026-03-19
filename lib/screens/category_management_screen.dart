import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/expense_service.dart';
import '../models/category.dart';

class CategoryManagementScreen extends StatelessWidget {
  const CategoryManagementScreen({super.key});

  void _showCategoryDialog(BuildContext context, {Category? category}) {
    final nameController = TextEditingController(text: category?.name ?? '');
    CategoryType selectedType = category?.type ?? CategoryType.expense;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(category == null ? 'Thêm danh mục' : 'Sửa danh mục'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Tên danh mục'),
              ),
              const SizedBox(height: 16),
              SegmentedButton<CategoryType>(
                segments: const [
                  ButtonSegment(value: CategoryType.expense, label: Text('Chi')),
                  ButtonSegment(value: CategoryType.income, label: Text('Thu')),
                ],
                selected: {selectedType},
                onSelectionChanged: (val) => setState(() => selectedType = val.first),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            TextButton(
              onPressed: () {
                if (nameController.text.isEmpty) return;
                final expenseService = Provider.of<ExpenseService>(context, listen: false);
                if (category == null) {
                  expenseService.addCategory(Category(
                    id: DateTime.now().toString(),
                    name: nameController.text,
                    icon: Icons.category,
                    color: Colors.blue,
                    type: selectedType,
                  ));
                } else {
                  expenseService.updateCategory(Category(
                    id: category.id,
                    name: nameController.text,
                    icon: category.icon,
                    color: category.color,
                    type: selectedType,
                  ));
                }
                Navigator.pop(context);
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenseService = Provider.of<ExpenseService>(context);
    final categories = expenseService.categories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý danh mục'),
      ),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          return Dismissible(
            key: Key(cat.id),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) => expenseService.deleteCategory(cat.id),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: cat.color, child: Icon(cat.icon, color: Colors.white)),
              title: Text(cat.name),
              subtitle: Text(cat.type == CategoryType.income ? 'Thu nhập' : 'Chi tiêu'),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showCategoryDialog(context, category: cat),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
