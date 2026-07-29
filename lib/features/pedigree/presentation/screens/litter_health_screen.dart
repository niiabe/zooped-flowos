import 'package:drift/drift.dart' as drift;
import 'package:sqlite3/sqlite3.dart' show SqliteException;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../providers/pedigree_providers.dart';

class LitterHealthScreen extends ConsumerStatefulWidget {
  final int litterId;

  const LitterHealthScreen({super.key, required this.litterId});

  @override
  ConsumerState<LitterHealthScreen> createState() => _LitterHealthScreenState();
}

class _LitterHealthScreenState extends ConsumerState<LitterHealthScreen> {
  final _recordTypeController = TextEditingController();
  final _notesController = TextEditingController();
  String _recordType = 'Vaccine';
  DateTime _date = DateTime.now();
  DateTime? _nextDueDate;

  @override
  void dispose() {
    _recordTypeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.padding(context);
    final isTablet = Responsive.isTablet(context);
    final puppiesAsync = ref.watch(_litterPuppiesProvider(widget.litterId));
    final healthAsync = ref.watch(_litterHealthRecordsProvider(widget.litterId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Litter Health Records'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Record to All Puppies',
              style: TextStyle(
                fontSize: isTablet ? 20.0 : 18.0,
                fontWeight: FontWeight.bold,
                color: AppTheme.secondaryColor,
              ),
            ),
            SizedBox(height: padding),

            DropdownButtonFormField<String>(
              initialValue: _recordType,
              decoration: const InputDecoration(
                labelText: 'Record Type *',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Vaccine', child: Text('Vaccine')),
                DropdownMenuItem(value: 'Deworming', child: Text('Deworming')),
                DropdownMenuItem(value: 'Vet Visit', child: Text('Vet Visit')),
                DropdownMenuItem(value: 'Heat Cycle', child: Text('Heat Cycle')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _recordType = value);
              },
            ),
            SizedBox(height: padding),

            TextFormField(
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Date *',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
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
              controller: TextEditingController(
                text: DateFormat.yMMMd().format(_date),
              ),
            ),
            SizedBox(height: padding),

            TextFormField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Next Due Date (Optional)',
                border: const OutlineInputBorder(),
                suffixIcon: _nextDueDate != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _nextDueDate = null),
                      )
                    : const Icon(Icons.event),
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (date != null) setState(() => _nextDueDate = date);
              },
              controller: TextEditingController(
                text: _nextDueDate != null ? DateFormat.yMMMd().format(_nextDueDate!) : '',
              ),
            ),
            SizedBox(height: padding),

            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes / Details',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: padding),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addRecordToAllPuppies,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                child: const Text('Add Record to All Puppies'),
              ),
            ),

            SizedBox(height: padding * 2),

            Text(
              'Existing Records',
              style: TextStyle(
                fontSize: isTablet ? 20.0 : 18.0,
                fontWeight: FontWeight.bold,
                color: AppTheme.secondaryColor,
              ),
            ),
            SizedBox(height: padding),

            puppiesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
              data: (puppies) {
                if (puppies.isEmpty) {
                  return const Text('No puppies in this litter');
                }
                return healthAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                  data: (records) {
                    if (records.isEmpty) {
                      return Text(
                        'No health records yet for ${puppies.length} puppies',
                        style: TextStyle(color: Colors.grey.shade600),
                      );
                    }
                    return Column(
                      children: [
                        if (records.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(bottom: padding * 0.5),
                            child: Text(
                              '${records.length} record${records.length == 1 ? '' : 's'} across ${puppies.length} puppies',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            ),
                          ),
                        ...records.map((record) => Card(
                          margin: EdgeInsets.only(bottom: padding * 0.5),
                          child: ListTile(
                            leading: Icon(
                              _getRecordIcon(record.recordType),
                              color: _getRecordColor(record.recordType),
                            ),
                            title: Text(record.recordType),
                            subtitle: Text(
                              '${DateFormat('yyyy-MM-dd').format(record.date)}${record.notes != null && record.notes!.isNotEmpty ? ' - ${record.notes}' : ''}',
                            ),
                            trailing: record.nextDueDate != null
                                ? Chip(
                                    label: Text(
                                      'Due: ${DateFormat('MM/dd').format(record.nextDueDate!)}',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  )
                                : null,
                          ),
                        )),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _getRecordIcon(String type) {
    switch (type) {
      case 'Vaccine': return Icons.vaccines;
      case 'Deworming': return Icons.medication;
      case 'Vet Visit': return Icons.local_hospital;
      case 'Heat Cycle': return Icons.water_drop;
      default: return Icons.health_and_safety;
    }
  }

  Color _getRecordColor(String type) {
    switch (type) {
      case 'Vaccine': return Colors.green;
      case 'Deworming': return Colors.orange;
      case 'Vet Visit': return Colors.blue;
      case 'Heat Cycle': return Colors.pink;
      default: return Colors.grey;
    }
  }

  Future<void> _addRecordToAllPuppies() async {
    try {
      final db = ref.read(databaseProvider);
      final puppies = await db.getPuppiesInLitter(widget.litterId);
      if (puppies.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No puppies in this litter')),
          );
        }
        return;
      }

      await db.addHealthRecordForLitterPuppies(
        widget.litterId,
        HealthRecordsCompanion.insert(
          dogId: puppies.first.id, // placeholder, will be overridden per puppy
          recordType: _recordType,
          date: _date,
          nextDueDate: _nextDueDate != null ? drift.Value(_nextDueDate!) : const drift.Value.absent(),
          notes: _notesController.text.isNotEmpty ? drift.Value(_notesController.text) : const drift.Value.absent(),
        ),
      );

      if (mounted) {
        ref.invalidate(_litterHealthRecordsProvider(widget.litterId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$_recordType added to ${puppies.length} puppies')),
        );
        _notesController.clear();
        setState(() {
          _nextDueDate = null;
          _date = DateTime.now();
        });
      }
    } on SqliteException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding records: $e')),
        );
      }
    }
  }
}

final _litterPuppiesProvider = FutureProvider.family.autoDispose<List<Dog>, int>((ref, litterId) async {
  final db = ref.watch(databaseProvider);
  return await db.getPuppiesInLitter(litterId);
});

final _litterHealthRecordsProvider = FutureProvider.family.autoDispose<List<HealthRecord>, int>((ref, litterId) async {
  final db = ref.watch(databaseProvider);
  return await db.getHealthRecordsForLitterPuppies(litterId);
});
