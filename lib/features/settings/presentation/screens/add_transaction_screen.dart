import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import '../../../../core/database/app_database.dart';
import '../../../pedigree/presentation/providers/pedigree_providers.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _type = 'Expense';
  String _category = 'Food/Supplies';
  DateTime _date = DateTime.now();

  final List<String> _expenseCategories = ['Food/Supplies', 'Vet/Medical', 'Stud Fee', 'Show/Event', 'Marketing', 'Other'];
  final List<String> _revenueCategories = ['Puppy Sale', 'Stud Service', 'Show Earnings', 'Other'];

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = _type == 'Expense' ? _expenseCategories : _revenueCategories;
    if (!categories.contains(_category)) {
      _category = categories.first;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Expense', label: Text('Expense'), icon: Icon(Icons.arrow_upward)),
                  ButtonSegment(value: 'Revenue', label: Text('Revenue'), icon: Icon(Icons.arrow_downward)),
                ],
                selected: {_type},
                onSelectionChanged: (set) {
                  setState(() => _type = set.first);
                },
              ),
              const SizedBox(height: 24),
              
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount (\$)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Enter an amount';
                  if (double.tryParse(val) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _category = val);
                },
              ),
              const SizedBox(height: 16),
              
              ListTile(
                title: const Text('Date'),
                subtitle: Text(DateFormat('MMM d, yyyy').format(_date)),
                trailing: const Icon(Icons.calendar_today),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: BorderSide(color: Colors.grey.shade400),
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) setState(() => _date = date);
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: _saveTransaction,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Save Transaction'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final db = ref.read(databaseProvider);
    await db.addTransaction(TransactionsCompanion.insert(
      transactionType: _type,
      category: _category,
      amount: double.parse(_amountController.text),
      date: _date,
      notes: _notesController.text.isNotEmpty ? drift.Value(_notesController.text) : const drift.Value.absent(),
    ));

    if (mounted) {
      context.pop();
    }
  }
}
