import 'package:drift/drift.dart' as drift;
import 'package:sqlite3/sqlite3.dart' show SqliteException;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/services/litter_report_service.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
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
  final _dateController = TextEditingController();
  final _nextDueDateController = TextEditingController();
  String _recordType = 'Vaccine';
  DateTime _date = DateTime.now();
  DateTime? _nextDueDate;
  bool _generatingPdf = false;
  bool _propagateToPuppies = true;

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat.yMMMd().format(_date);
  }

  Future<void> _generatePdf(WidgetRef ref) async {
    setState(() => _generatingPdf = true);
    try {
      final repo = ref.read(pedigreeRepositoryProvider);
      final settingsRepo = ref.read(settingsRepositoryProvider);
      final litter = await repo.getLitterById(widget.litterId);
      if (litter == null) return;
      
      final sire = await repo.getDogByIdFlat(litter.sireId);
      final dam = await repo.getDogByIdFlat(litter.damId);
      final puppies = await repo.getPuppiesInLitter(widget.litterId);
      final healthRecords = await repo.getLitterHealthRecords(widget.litterId);
      var profile = await settingsRepo.getKennelProfile();
      
      final payload = LitterReportPayload(
        kennelProfile: profile,
        litter: litter,
        sire: sire,
        dam: dam,
        puppies: puppies,
        healthRecords: healthRecords,
      );
      
      final pdfBytes = await LitterReportService.generateReport(payload);
      await LitterReportService.sharePdf(pdfBytes, widget.litterId.toString());
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _generatingPdf = false);
      }
    }
  }

  @override
  void dispose() {
    _recordTypeController.dispose();
    _notesController.dispose();
    _dateController.dispose();
    _nextDueDateController.dispose();
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
        actions: [
          IconButton(
            onPressed: _generatingPdf ? null : () => _generatePdf(ref),
            icon: _generatingPdf 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.picture_as_pdf),
            tooltip: 'Generate PDF Report',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Record to Litter',
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
                if (date != null) {
                  setState(() {
                    _date = date;
                    _dateController.text = DateFormat.yMMMd().format(date);
                  });
                }
              },
              controller: _dateController,
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
                        onPressed: () => setState(() {
                          _nextDueDate = null;
                          _nextDueDateController.clear();
                        }),
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
                if (date != null) {
                  setState(() {
                    _nextDueDate = date;
                    _nextDueDateController.text = DateFormat.yMMMd().format(date);
                  });
                }
              },
              controller: _nextDueDateController,
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

            CheckboxListTile(
              title: const Text('Apply to all puppies'),
              subtitle: const Text('Also add this record to each puppy in the litter'),
              value: _propagateToPuppies,
              onChanged: (value) {
                setState(() => _propagateToPuppies = value ?? true);
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            SizedBox(height: padding),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addRecordToLitter,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                child: const Text('Save to Litter Records'),
              ),
            ),

            SizedBox(height: padding * 2),

            Text(
              'Existing Litter Records',
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
                        'No health records yet for this litter',
                        style: TextStyle(color: Colors.grey.shade600),
                      );
                    }
                    return Column(
                      children: [
                        if (records.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(bottom: padding * 0.5),
                            child: Text(
                              '${records.length} record${records.length == 1 ? '' : 's'} for this litter',
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

            SizedBox(height: padding * 2),

            Text(
              'Puppy Health Records',
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
                  return const SizedBox.shrink();
                }
                final puppyRecordsAsync = ref.watch(_litterPuppiesHealthRecordsProvider(widget.litterId));
                return puppyRecordsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                  data: (puppyRecords) {
                    if (puppyRecords.isEmpty) {
                      return Text(
                        'No propagated health records yet. Use "Apply to all puppies" when adding a record.',
                        style: TextStyle(color: Colors.grey.shade600),
                      );
                    }
                    final puppyMap = {for (final p in puppies) p.id: p};
                    final grouped = <int, List<HealthRecord>>{};
                    for (final record in puppyRecords) {
                      grouped.putIfAbsent(record.dogId, () => []).add(record);
                    }
                    return Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(bottom: padding * 0.5),
                          child: Text(
                            '${puppyRecords.length} record${puppyRecords.length == 1 ? '' : 's'} across ${grouped.length} puppy${grouped.length == 1 ? '' : 'ies'}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                        ),
                        ...grouped.entries.map((entry) {
                          final puppy = puppyMap[entry.key];
                          final records = entry.value;
                          return Card(
                            margin: EdgeInsets.only(bottom: padding * 0.5),
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.secondaryColor.withValues(alpha: 0.1),
                                child: Text(
                                  '${records.length}',
                                  style: TextStyle(color: AppTheme.secondaryColor, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(puppy?.callName ?? 'Unknown Puppy'),
                              subtitle: Text(
                                '${records.length} record${records.length == 1 ? '' : 's'}',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                              children: records.map((record) => ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                                leading: Icon(
                                  _getRecordIcon(record.recordType),
                                  color: _getRecordColor(record.recordType),
                                  size: 20,
                                ),
                                title: Text(record.recordType, style: const TextStyle(fontSize: 14)),
                                subtitle: Text(
                                  '${DateFormat('yyyy-MM-dd').format(record.date)}${record.notes != null && record.notes!.isNotEmpty ? ' - ${record.notes}' : ''}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: record.nextDueDate != null
                                    ? Chip(
                                        label: Text(
                                          'Due: ${DateFormat('MM/dd').format(record.nextDueDate!)}',
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        visualDensity: VisualDensity.compact,
                                      )
                                    : null,
                              )).toList(),
                            ),
                          );
                        }),
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

  Future<void> _addRecordToLitter() async {
    try {
      final repo = ref.read(pedigreeRepositoryProvider);

      await repo.addLitterHealthRecord(
        LitterHealthRecordsCompanion.insert(
          litterId: widget.litterId,
          recordType: _recordType,
          date: _date,
          nextDueDate: _nextDueDate != null ? drift.Value(_nextDueDate!) : const drift.Value.absent(),
          notes: _notesController.text.isNotEmpty ? drift.Value(_notesController.text) : const drift.Value.absent(),
        ),
      );

      if (_propagateToPuppies) {
        await repo.addHealthRecordForLitterPuppies(
          widget.litterId,
          _recordType,
          _date,
          nextDueDate: _nextDueDate,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        );
      }

      if (mounted) {
        ref.invalidate(_litterHealthRecordsProvider(widget.litterId));
        if (_propagateToPuppies) {
          ref.invalidate(_litterPuppiesHealthRecordsProvider(widget.litterId));
        }
        final message = _propagateToPuppies
            ? '$_recordType added to litter and all puppies'
            : '$_recordType added to litter records';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        _notesController.clear();
        setState(() {
          _nextDueDate = null;
          _date = DateTime.now();
          _dateController.text = DateFormat.yMMMd().format(DateTime.now());
          _nextDueDateController.clear();
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

final _litterHealthRecordsProvider = FutureProvider.family.autoDispose<List<LitterHealthRecord>, int>((ref, litterId) async {
  final repo = ref.watch(pedigreeRepositoryProvider);
  return await repo.getLitterHealthRecords(litterId);
});

final _litterPuppiesHealthRecordsProvider = FutureProvider.family.autoDispose<List<HealthRecord>, int>((ref, litterId) async {
  final repo = ref.watch(pedigreeRepositoryProvider);
  return await repo.getHealthRecordsForLitterPuppies(litterId);
});
