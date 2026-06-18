import 'package:drift/drift.dart' as drift;
import 'package:sqlite3/sqlite3.dart' show SqliteException;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/utils/responsive.dart';
import '../providers/pedigree_providers.dart';
import '../../../../core/services/notification_service.dart';

class AddHealthRecordScreen extends ConsumerStatefulWidget {
  final int dogId;

  const AddHealthRecordScreen({super.key, required this.dogId});

  @override
  ConsumerState<AddHealthRecordScreen> createState() => _AddHealthRecordScreenState();
}

class _AddHealthRecordScreenState extends ConsumerState<AddHealthRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  String _recordType = 'Vaccine';
  DateTime _date = DateTime.now();
  DateTime? _nextDueDate;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.padding(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Health Record'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                maxLines: 4,
              ),
              SizedBox(height: padding * 2),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveRecord,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                  ),
                  child: const Text('Save Record'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final db = ref.read(databaseProvider);
      final id = await db.addHealthRecord(HealthRecordsCompanion.insert(
        dogId: widget.dogId,
        recordType: _recordType,
        date: _date,
        nextDueDate: _nextDueDate != null ? drift.Value(_nextDueDate!) : const drift.Value.absent(),
        notes: _notesController.text.isNotEmpty ? drift.Value(_notesController.text) : const drift.Value.absent(),
      ));

      if (_nextDueDate != null) {
        // Schedule notification at 9 AM on the due date
        final scheduleTime = DateTime(_nextDueDate!.year, _nextDueDate!.month, _nextDueDate!.day, 9, 0);
        await NotificationService().scheduleNotification(
          id: id.hashCode,
          title: 'Health Reminder: $_recordType',
          body: 'Your dog has an upcoming $_recordType appointment.',
          scheduledDate: scheduleTime,
        );
      }

      if (mounted) {
        ref.invalidate(healthRecordsProvider(widget.dogId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Health record saved successfully')),
        );
        context.pop();
      }
    } on SqliteException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message.contains('UNIQUE')
                ? 'A record with this name already exists'
                : 'Error saving record: $e'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving record: $e')),
        );
      }
    }
  }
}
