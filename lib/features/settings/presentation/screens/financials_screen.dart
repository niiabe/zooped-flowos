import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
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
          for (final t in transactions) {
            if (t.transactionType == 'Revenue') {
              totalRevenue += t.amount;
            } else {
              totalExpense += t.amount;
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
