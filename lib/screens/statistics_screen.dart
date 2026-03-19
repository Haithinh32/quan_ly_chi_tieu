import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/expense_service.dart';
import '../models/category.dart';
import 'category_management_screen.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final expenseService = Provider.of<ExpenseService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê chi tiết'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const CategoryManagementScreen()),
            ),
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Ngày'),
            Tab(text: 'Tháng'),
            Tab(text: 'Năm'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStatView(expenseService, 'day'),
          _buildStatView(expenseService, 'month'),
          _buildStatView(expenseService, 'year'),
        ],
      ),
    );
  }

  Widget _buildStatView(ExpenseService service, String period) {
    final now = DateTime.now();
    final transactions = service.transactions.where((t) {
      if (period == 'day') {
        return t.date.day == now.day && t.date.month == now.month && t.date.year == now.year;
      } else if (period == 'month') {
        return t.date.month == now.month && t.date.year == now.year;
      } else {
        return t.date.year == now.year;
      }
    }).toList();

    final expenses = transactions.where((t) => t.type == CategoryType.expense).toList();
    final totalExpense = expenses.fold(0.0, (sum, t) => sum + t.amount);
    
    final categoryMap = <String, double>{};
    for (var t in expenses) {
      categoryMap[t.categoryId] = (categoryMap[t.categoryId] ?? 0) + t.amount;
    }

    if (expenses.isEmpty) {
      return const Center(child: Text('Không có dữ liệu chi tiêu cho giai đoạn này'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('Phân bổ chi tiêu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: categoryMap.entries.map((e) {
                  final category = service.getCategoryById(e.key);
                  return PieChartSectionData(
                    color: category.color,
                    value: e.value,
                    title: '${(e.value / totalExpense * 100).toStringAsFixed(0)}%',
                    radius: 60,
                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text('So sánh giữa các hạng mục', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildBarChart(categoryMap, service),
          const SizedBox(height: 32),
          const Text('Chi tiết chi tiêu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...categoryMap.entries.map((e) {
            final category = service.getCategoryById(e.key);
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: category.color, child: Icon(category.icon, color: Colors.white)),
                title: Text(category.name),
                trailing: Text(currencyFormat.format(e.value), style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: LinearProgressIndicator(
                  value: e.value / totalExpense,
                  backgroundColor: Colors.grey.shade200,
                  color: category.color,
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildBarChart(Map<String, double> data, ExpenseService service) {
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: data.values.isEmpty ? 100 : data.values.reduce((a, b) => a > b ? a : b) * 1.2,
          barGroups: data.entries.toList().asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.value,
                  color: service.getCategoryById(e.value.key).color,
                  width: 16,
                  borderRadius: BorderRadius.circular(4),
                )
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= data.length) return const Text('');
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      service.getCategoryById(data.keys.elementAt(index)).name.substring(0, 3),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}
