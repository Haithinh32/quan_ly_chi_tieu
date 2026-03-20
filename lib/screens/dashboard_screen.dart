import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/expense_service.dart';
import '../models/category.dart';
// THÊM IMPORT NÀY:
import 'transaction_form_screen.dart'; 

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _touchedPieIndex = -1;
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng ☀️';
    if (hour < 18) return 'Chào buổi chiều 🌤️';
    return 'Chào buổi tối 🌙';
  }

  // Hàm mở màn hình Thêm/Sửa của Thịnh
  void _openTransactionForm(BuildContext context, {Map<String, dynamic>? data}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionFormScreen(existingTransaction: data),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('$feature sắp ra mắt'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<ExpenseService>(context);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, service),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 88),
              child: Column(
                children: [
                  _buildOverviewCard(service),
                  _buildPieChartCard(context, service),
                  _buildBarChartCard(service),
                  _buildRecentTransactionsCard(context, service),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        // ĐÃ SỬA: Mở Form của Thịnh
        onPressed: () => _openTransactionForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Thêm'),
        tooltip: 'Thêm giao dịch mới',
      ),
    );
  }

  // ─────────────────────────── SliverAppBar ────────────────────────────────

  SliverAppBar _buildSliverAppBar(BuildContext context, ExpenseService service) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: Colors.blue.shade700,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Expense tracker - G15_C3',
            style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w400),
          ),
          Text(
            'Tài chính',
            style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue.shade800, Colors.blue.shade500],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    _greeting,
                    style: const TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Số dư hiện tại',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currencyFormat.format(service.balance),
                    style: TextStyle(
                      color: service.balance >= 0 ? Colors.white : Colors.orange.shade200,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────── Overview Card (3 cột) ──────────────────────────

  Widget _buildOverviewCard(ExpenseService service) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Row(
          children: [
            Expanded(
              child: _buildSummaryTile(
                label: 'Tổng thu',
                amount: service.totalIncome,
                color: Colors.green,
                icon: Icons.trending_up_rounded,
              ),
            ),
            Container(width: 1, height: 56, color: Colors.grey.shade200),
            Expanded(
              child: _buildSummaryTile(
                label: 'Tổng chi',
                amount: service.totalExpense,
                color: Colors.red,
                icon: Icons.trending_down_rounded,
              ),
            ),
            Container(width: 1, height: 56, color: Colors.grey.shade200),
            Expanded(
              child: _buildSummaryTile(
                label: 'Số dư',
                amount: service.balance,
                color: service.balance >= 0 ? Colors.blue : Colors.orange,
                icon: Icons.account_balance_wallet_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryTile({
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            _currencyFormat.format(amount),
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ],
    );
  }

  // ───────────────────────── Biểu đồ tròn (Pie) ───────────────────────────

  Widget _buildPieChartCard(BuildContext context, ExpenseService service) {
    final Map<String, double> expenseByCategory = {};
    for (final t in service.transactions) {
      if (t.type == CategoryType.expense) {
        expenseByCategory[t.categoryId] =
            (expenseByCategory[t.categoryId] ?? 0) + t.amount;
      }
    }

    if (expenseByCategory.isEmpty) {
      return _buildEmptyCard(
        title: 'Chi tiêu theo danh mục',
        icon: Icons.pie_chart_outline,
        message: 'Chưa có dữ liệu chi tiêu',
      );
    }

    final total = expenseByCategory.values.fold(0.0, (sum, v) => sum + v);
    final entries = expenseByCategory.entries.toList();

    final sections = List.generate(entries.length, (i) {
      final entry = entries[i];
      final category = service.getCategoryById(entry.key);
      final pct = entry.value / total * 100;
      final isTouched = i == _touchedPieIndex;
      return PieChartSectionData(
        value: entry.value,
        color: category.color,
        title: isTouched ? '${pct.toStringAsFixed(1)}%' : '',
        radius: isTouched ? 72 : 58,
        titleStyle: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
      );
    });

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chi tiêu theo danh mục',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Text(
                  _currencyFormat.format(total),
                  style: TextStyle(
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.w500,
                      fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 160,
                  width: 160,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                response == null ||
                                response.touchedSection == null) {
                              _touchedPieIndex = -1;
                            } else {
                              _touchedPieIndex =
                                  response.touchedSection!.touchedSectionIndex;
                            }
                          });
                        },
                      ),
                      sections: sections,
                      centerSpaceRadius: 36,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: entries.map((entry) {
                      final category = service.getCategoryById(entry.key);
                      final pct = entry.value / total * 100;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                  color: category.color, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                category.name,
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${pct.toStringAsFixed(0)}%',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────── Biểu đồ cột (Bar) ─────────────────────────────

  Widget _buildBarChartCard(ExpenseService service) {
    final now = DateTime.now();
    final months =
        List.generate(6, (i) => DateTime(now.year, now.month - (5 - i), 1));

    final Map<String, double> incomeByMonth = {};
    final Map<String, double> expenseByMonth = {};
    for (final t in service.transactions) {
      final key = '${t.date.year}-${t.date.month}';
      if (t.type == CategoryType.income) {
        incomeByMonth[key] = (incomeByMonth[key] ?? 0) + t.amount;
      } else {
        expenseByMonth[key] = (expenseByMonth[key] ?? 0) + t.amount;
      }
    }

    final barGroups = List.generate(months.length, (i) {
      final key = '${months[i].year}-${months[i].month}';
      return BarChartGroupData(
        x: i,
        barsSpace: 4,
        barRods: [
          BarChartRodData(
            toY: incomeByMonth[key] ?? 0,
            color: Colors.green.shade400,
            width: 10,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: expenseByMonth[key] ?? 0,
            color: Colors.red.shade400,
            width: 10,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    });

    final maxY = 1000000.0; // Tùy chỉnh theo dữ liệu thực tế

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thu/Chi 6 tháng gần đây',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildLegendDot(Colors.green.shade400, 'Thu nhập'),
                const SizedBox(width: 16),
                _buildLegendDot(Colors.red.shade400, 'Chi tiêu'),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: barGroups,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= months.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              DateFormat('MM/yy').format(months[idx]),
                              style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  // ──────────────────────── Giao dịch gần đây ──────────────────────────────

  Widget _buildRecentTransactionsCard(BuildContext context, ExpenseService service) {
    final recent = service.transactions.take(5).toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Giao dịch gần đây',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => _showComingSoon(context, 'Danh sách giao dịch'),
                  child: const Text('Xem tất cả', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          if (recent.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  Text('Chưa có giao dịch nào', style: TextStyle(color: Colors.grey.shade500)),
                  const SizedBox(height: 4),
                  // ĐÃ SỬA: Mở Form của Thịnh
                  TextButton.icon(
                    onPressed: () => _openTransactionForm(context),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Thêm giao dịch đầu tiên'),
                  ),
                ],
              ),
            )
          else
            ...recent.map((t) {
              final category = service.getCategoryById(t.categoryId);
              final isIncome = t.type == CategoryType.income;
              return Column(
                children: [
                  InkWell(
                    // ĐÃ SỬA: Nhấn để Sửa giao dịch
                    onTap: () => _openTransactionForm(context, data: {
                      'id': t.id,
                      'title': t.note.isNotEmpty ? t.note : category.name,
                      'amount': t.amount,
                      'date': t.date,
                      'type': isIncome ? 'income' : 'expense',
                      'note': t.note,
                    }),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: category.color.withOpacity(0.15),
                            child: Icon(category.icon, color: category.color, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                Text(DateFormat('dd/MM/yyyy').format(t.date), style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                              ],
                            ),
                          ),
                          Text(
                            '${isIncome ? '+' : '-'}${_currencyFormat.format(t.amount)}',
                            style: TextStyle(
                              color: isIncome ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Divider(height: 1, indent: 56, color: Colors.grey.shade100),
                ],
              );
            }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildEmptyCard({required String title, required IconData icon, required String message}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  Icon(icon, size: 40, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  Text(message, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}