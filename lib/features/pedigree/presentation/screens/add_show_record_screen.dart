import 'package:drift/drift.dart' as drift;
import 'package:sqlite3/sqlite3.dart' show SqliteException;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/utils/responsive.dart';
import '../providers/pedigree_providers.dart';

class AddShowRecordScreen extends ConsumerStatefulWidget {
  final int dogId;

  const AddShowRecordScreen({super.key, required this.dogId});

  @override
  ConsumerState<AddShowRecordScreen> createState() => _AddShowRecordScreenState();
}

class _AddShowRecordScreenState extends ConsumerState<AddShowRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _eventNameController = TextEditingController();
  final _judgeController = TextEditingController();
  final _placementController = TextEditingController();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _eventNameController.dispose();
    _judgeController.dispose();
    _placementController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.padding(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Show Record'),
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _eventNameController,
                decoration: const InputDecoration(
                  labelText: 'Event / Show Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.emoji_events),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter event name' : null,
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
                controller: _judgeController,
                decoration: const InputDecoration(
                  labelText: 'Judge (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              SizedBox(height: padding),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _placementController,
                      decoration: const InputDecoration(
                        labelText: 'Placement / Score',
                        hintText: 'e.g. 1st, V1, Best in Show',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: padding),
                  Expanded(
                    child: TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title Awarded',
                        hintText: 'e.g. CH, GCH, IPO1',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: padding),

              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Judge Comments / Notes',
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
      await db.addShowRecord(ShowRecordsCompanion.insert(
        dogId: widget.dogId,
        eventName: _eventNameController.text,
        date: _date,
        judge: _judgeController.text.isNotEmpty ? drift.Value(_judgeController.text) : const drift.Value.absent(),
        placement: _placementController.text.isNotEmpty ? drift.Value(_placementController.text) : const drift.Value.absent(),
        titleAwarded: _titleController.text.isNotEmpty ? drift.Value(_titleController.text) : const drift.Value.absent(),
        notes: _notesController.text.isNotEmpty ? drift.Value(_notesController.text) : const drift.Value.absent(),
      ));

      if (mounted) {
        ref.invalidate(showRecordsProvider(widget.dogId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Show record saved successfully')),
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
