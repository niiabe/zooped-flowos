import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/database/app_database.dart';
import '../../../pedigree/presentation/providers/pedigree_providers.dart';

final transactionsProvider = StreamProvider.autoDispose<List<Transaction>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchTransactions();
});

class FinancialsScreen extends ConsumerWidget {
  const FinancialsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kennel Financials'),
      ),
      body: transactionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (transactions) {
          if (transactions.isEmpty) {
            return const Center(child: Text('No transactions yet.'));
          }

          double totalRevenue = 0;
          double totalExpense = 0;
          final expenseByCategory = <String, double>{};

          for (final t in transactions) {
            if (t.transactionType == 'Revenue') {
              totalRevenue += t.amount;
            } else {
              totalExpense += t.amount;
              expenseByCategory[t.category] = (expenseByCategory[t.category] ?? 0) + t.amount;
            }
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text('Net Profit/Loss', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        NumberFormat.currency(symbol: '\$').format(totalRevenue - totalExpense),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: (totalRevenue - totalExpense) >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatColumn('Revenue', totalRevenue, Colors.green),
                          Container(width: 1, height: 40, color: Colors.grey.shade300),
                          _buildStatColumn('Expenses', totalExpense, Colors.red),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (totalRevenue > 0 || totalExpense > 0)
                _buildBarChart(totalRevenue, totalExpense),
              if (expenseByCategory.isNotEmpty)
                _buildExpensePieChart(expenseByCategory),
              const SizedBox(height: 24),
              const Text('Transaction History', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...transactions.map((t) => _buildTransactionCard(t, ref)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/settings/financials/new'),
        icon: const Icon(Icons.add),
        label: const Text('Add Transaction'),
      ),
    );
  }

  Widget _buildStatColumn(String label, double amount, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        Text(
          NumberFormat.currency(symbol: '\$').format(amount),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildBarChart(double revenue, double expense) {
    final maxVal = (revenue > expense ? revenue : expense) * 1.2;
    if (maxVal == 0) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Revenue vs Expenses', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxVal,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 14);
                          String text;
                          if (value == 0) text = 'Revenue';
                          else if (value == 1) text = 'Expenses';
                          else text = '';
                          return SideTitleWidget(meta: meta, child: Text(text, style: style));
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const SizedBox.shrink();
                          return SideTitleWidget(
                            meta: meta,
                            child: Text('\$${(value / 1000).toStringAsFixed(1)}k', style: const TextStyle(fontSize: 10)),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(toY: revenue, color: Colors.green, width: 22, borderRadius: BorderRadius.circular(4)),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(toY: expense, color: Colors.red, width: 22, borderRadius: BorderRadius.circular(4)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensePieChart(Map<String, double> expenseByCategory) {
    final colors = [
      Colors.blue, Colors.orange, Colors.purple, Colors.pink,
      Colors.teal, Colors.cyan, Colors.indigo, Colors.amber,
    ];
    
    int colorIndex = 0;
    final List<PieChartSectionData> sections = [];
    final List<Widget> legendItems = [];

    expenseByCategory.forEach((category, amount) {
      final color = colors[colorIndex % colors.length];
      sections.add(
        PieChartSectionData(
          color: color,
          value: amount,
          title: '', // don't show title inside the pie because it can get crowded
          radius: 50,
        ),
      );
      legendItems.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 12, height: 12, color: color),
            const SizedBox(width: 4),
            Text('$category: \$${amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12)),
          ],
        )
      );
      colorIndex++;
    });

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Expenses Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: PieChart(
                      PieChartData(
                        sections: sections,
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: SingleChildScrollView(
                      child: Wrap(
                        direction: Axis.vertical,
                        spacing: 8,
                        children: legendItems,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Transaction t, WidgetRef ref) {
    final isRevenue = t.transactionType == 'Revenue';
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isRevenue ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
          child: Icon(
            isRevenue ? Icons.arrow_downward : Icons.arrow_upward,
            color: isRevenue ? Colors.green : Colors.red,
          ),
        ),
        title: Text(t.category, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(DateFormat('MMM d, yyyy').format(t.date)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              NumberFormat.currency(symbol: '\$').format(t.amount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isRevenue ? Colors.green : Colors.red,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.grey),
              onPressed: () {
                ref.read(databaseProvider).deleteTransaction(t.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}
